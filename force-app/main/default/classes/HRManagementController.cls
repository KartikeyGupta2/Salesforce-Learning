public with sharing class HRManagementController {

    public class DashboardStats {
        @AuraEnabled public Integer openPositions { get; set; }
        @AuraEnabled public Integer activeApplications { get; set; }
        @AuraEnabled public Integer pendingOffers { get; set; }
        @AuraEnabled public Integer activeOnboardings { get; set; }
        @AuraEnabled public Decimal avgInterviewRating { get; set; }
    }

    public class OnboardingProgressWrapper {
        @AuraEnabled public Id applicationId { get; set; }
        @AuraEnabled public String candidateName { get; set; }
        @AuraEnabled public String positionTitle { get; set; }
        @AuraEnabled public String buddyName { get; set; }
        @AuraEnabled public Date orientationDate { get; set; }
        @AuraEnabled public Integer totalTasks { get; set; }
        @AuraEnabled public Integer verifiedTasks { get; set; }
        @AuraEnabled public Integer progressPercent { get; set; }
    }

    @AuraEnabled(cacheable=false)
    public static DashboardStats getDashboardStats() {
        DashboardStats stats = new DashboardStats();

        // 1. Count Open Positions
        stats.openPositions = [SELECT COUNT() FROM Position__c WHERE Status__c = 'Open - Approved' WITH SECURITY_ENFORCED];

        // 2. Count Active Applications
        stats.activeApplications = [SELECT COUNT() 
                                    FROM Job_Application__c 
                                    WHERE Status__c != 'Joined' AND Status__c != 'Rejected'
                                    WITH SECURITY_ENFORCED];

        // 3. Count Pending Offers
        stats.pendingOffers = [SELECT COUNT() FROM Offer__c WHERE Status__c = 'Pending Approval' WITH SECURITY_ENFORCED];

        // 4. Count Active Onboarding Pipelines
        stats.activeOnboardings = [SELECT COUNT() 
                                    FROM Job_Application__c 
                                    WHERE Onboarding_Status__c = 'In Progress'
                                    WITH SECURITY_ENFORCED];

        // 5. Compute Average Interview Rating
        List<Interview__c> completedInterviews = [SELECT Rating__c 
                                                  FROM Interview__c 
                                                  WHERE Status__c = 'Completed' AND Rating__c != null
                                                  WITH SECURITY_ENFORCED];
        if (completedInterviews.isEmpty()) {
            stats.avgInterviewRating = 0.0;
        } else {
            Decimal totalScore = 0;
            for (Interview__c interview : completedInterviews) {
                if (interview.Rating__c == 'Strong Yes') {
                    totalScore += 4;
                } else if (interview.Rating__c == 'Yes') {
                    totalScore += 3;
                } else if (interview.Rating__c == 'No') {
                    totalScore += 2;
                } else if (interview.Rating__c == 'Strong No') {
                    totalScore += 1;
                }
            }
            stats.avgInterviewRating = (totalScore / completedInterviews.size()).setScale(2);
        }

        return stats;
    }

    @AuraEnabled(cacheable=false)
    public static List<Offer__c> getPendingOffers() {
        return [SELECT Id, Name, Designation__c, CTC__c, Joining_Date__c, Validity_Date__c,
                       Job_Application__r.Candidate__r.First_Name__c, Job_Application__r.Candidate__r.Last_Name__c,
                       Job_Application__r.Position__r.Name
                FROM Offer__c
                WHERE Status__c = 'Pending Approval'
                WITH SECURITY_ENFORCED
                ORDER BY CreatedDate DESC];
    }

    @AuraEnabled(cacheable=false)
    public static List<Job_Application__c> getRecentApplications() {
        return [SELECT Id, Name, Status__c, Age_In_Days__c, CreatedDate,
                       Candidate__r.First_Name__c, Candidate__r.Last_Name__c,
                       Position__r.Name
                FROM Job_Application__c
                WITH SECURITY_ENFORCED
                ORDER BY CreatedDate DESC
                LIMIT 5];
    }

    @AuraEnabled(cacheable=false)
    public static List<OnboardingProgressWrapper> getOnboardingProgress() {
        List<OnboardingProgressWrapper> results = new List<OnboardingProgressWrapper>();

        List<Job_Application__c> onboardings = [SELECT Id, Candidate__r.First_Name__c, Candidate__r.Last_Name__c,
                                                       Position__r.Name, Onboarding_Buddy__r.Name, Orientation_Date__c,
                                                       (SELECT Id, Status__c FROM Onboarding_Tasks__r)
                                                FROM Job_Application__c
                                                WHERE Onboarding_Status__c = 'In Progress'
                                                WITH SECURITY_ENFORCED
                                                ORDER BY Orientation_Date__c ASC];

        for (Job_Application__c app : onboardings) {
            OnboardingProgressWrapper wrapper = new OnboardingProgressWrapper();
            wrapper.applicationId = app.Id;
            wrapper.candidateName = app.Candidate__r.First_Name__c + ' ' + app.Candidate__r.Last_Name__c;
            wrapper.positionTitle = app.Position__r.Name;
            wrapper.buddyName = app.Onboarding_Buddy__r != null ? app.Onboarding_Buddy__r.Name : 'Not Assigned';
            wrapper.orientationDate = app.Orientation_Date__c;

            Integer total = app.Onboarding_Tasks__r.size();
            Integer verified = 0;
            for (Onboarding_Task__c task : app.Onboarding_Tasks__r) {
                if (task.Status__c == 'Verified') {
                    verified++;
                }
            }

            wrapper.totalTasks = total;
            wrapper.verifiedTasks = verified;
            wrapper.progressPercent = total == 0 ? 0 : Integer.valueOf(((Decimal)verified / total) * 100);
            results.add(wrapper);
        }

        return results;
    }

    @AuraEnabled(cacheable=false)
    public static void approveOffer(Id offerId) {
        if (!Schema.sObjectType.Offer__c.isUpdateable() || !Schema.sObjectType.Job_Application__c.isUpdateable()) {
            throw new AuraHandledException('Insufficient permissions to approve offer.');
        }

        Offer__c offer = [SELECT Id, Job_Application__c FROM Offer__c WHERE Id = :offerId WITH SECURITY_ENFORCED LIMIT 1];
        offer.Status__c = 'Approved';
        update offer;

        Job_Application__c app = new Job_Application__c(
            Id = offer.Job_Application__c,
            Status__c = 'Selected'
        );
        update app;

        // Send the offer email to the candidate
        sendOfferEmail(offer);
    }

    private static void sendOfferEmail(Offer__c offer) {
        // Query candidate and position details
        Offer__c fullOffer = [
            SELECT Designation__c, CTC__c, Joining_Date__c, Benefits__c, Validity_Date__c,
                   Job_Application__r.Candidate__r.First_Name__c, Job_Application__r.Candidate__r.Last_Name__c,
                   Job_Application__r.Candidate__r.Email__c, Job_Application__r.Position__r.Name
            FROM Offer__c
            WHERE Id = :offer.Id
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];

        if (String.isNotBlank(fullOffer.Job_Application__r.Candidate__r.Email__c)) {
            String candidateName = fullOffer.Job_Application__r.Candidate__r.First_Name__c + ' ' + fullOffer.Job_Application__r.Candidate__r.Last_Name__c;
            
            // Format dates
            String formattedJoiningDate = fullOffer.Joining_Date__c != null ? fullOffer.Joining_Date__c.format() : 'To Be Decided';
            String formattedValidityDate = fullOffer.Validity_Date__c != null ? fullOffer.Validity_Date__c.format() : 'N/A';

            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new List<String>{fullOffer.Job_Application__r.Candidate__r.Email__c});
            email.setSubject('Official Job Offer: ' + fullOffer.Job_Application__r.Position__r.Name);
            email.setPlainTextBody(
                'Dear ' + candidateName + ',\n\n' +
                'Congratulations! We are pleased to offer you the position of ' + fullOffer.Designation__c + ' for our ' + fullOffer.Job_Application__r.Position__r.Name + ' role.\n\n' +
                'Offer Details:\n' +
                '- Designation: ' + fullOffer.Designation__c + '\n' +
                '- CTC: $' + fullOffer.CTC__c + '\n' +
                '- Joining Date: ' + formattedJoiningDate + '\n' +
                '- Benefits: ' + (String.isNotBlank(fullOffer.Benefits__c) ? fullOffer.Benefits__c : 'Standard corporate package') + '\n' +
                '- Offer Validity Date: ' + formattedValidityDate + '\n\n' +
                'Please review this offer and let us know your decision by replying to this email or through our applicant portal.\n\n' +
                'Welcome to the team!\n\n' +
                'Best regards,\nHR Management Team'
            );
            
            try {
                Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{email});
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR, 'Failed to send offer email: ' + e.getMessage());
            }
        }
    }

    @AuraEnabled(cacheable=false)
    public static void rejectOffer(Id offerId, String reason) {
        if (String.isBlank(reason)) {
            throw new AuraHandledException('Rejection reason is required.');
        }
        if (!Schema.sObjectType.Offer__c.isUpdateable() || !Schema.sObjectType.Job_Application__c.isUpdateable()) {
            throw new AuraHandledException('Insufficient permissions to reject offer.');
        }

        Offer__c offer = [SELECT Id, Job_Application__c FROM Offer__c WHERE Id = :offerId WITH SECURITY_ENFORCED LIMIT 1];
        offer.Status__c = 'Rejected';
        offer.Rejection_Reason__c = reason;
        update offer;

        Job_Application__c app = new Job_Application__c(
            Id = offer.Job_Application__c,
            Status__c = 'Rejected',
            Rejection_Reason__c = reason
        );
        update app;
    }

    @AuraEnabled(cacheable=false)
    public static Id clonePosition(Id positionId) {
        if (positionId == null) {
            throw new AuraHandledException('Position ID cannot be null.');
        }

        Position__c original = [
            SELECT Name, Department__c, Location__c, Type__c, Target_Hires__c,
                   Min_Pay__c, Max_Pay__c, Educational_Requirements__c,
                   Skills_Required__c, Responsibilities__c, Job_Description__c,
                   Apex__c, C_Sharp__c, Java__c, JavaScript__c, Job_Level__c,
                   Functional_Area__c, Travel_Required__c
            FROM Position__c
            WHERE Id = :positionId
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];
                                
        Position__c cloned = original.clone(false, true, false, false);
        cloned.Status__c = 'New Position'; // Default status to draft status
        cloned.Open_Date__c = null;        // Clear open date
        cloned.Close_Date__c = null;       // Clear close date
        cloned.Hire_By__c = null;          // Clear hire by date
        cloned.Hired_Count__c = 0;         // Reset hired count
        
        if (Schema.sObjectType.Position__c.isCreateable()) {
            insert cloned;
            return cloned.Id;
        } else {
            throw new AuraHandledException('Insufficient permissions to create Position');
        }
    }
}
