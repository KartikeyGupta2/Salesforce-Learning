public with sharing class InterviewTriggerHandler {

    public static void handleAfterInsert(List<Interview__c> newList) {
        sendInterviewInvites(newList);
    }

    private static void sendInterviewInvites(List<Interview__c> newList) {
        Set<Id> jobAppIds = new Set<Id>();
        Set<Id> interviewerIds = new Set<Id>();

        for (Interview__c interview : newList) {
            jobAppIds.add(interview.Job_Application__c);
            interviewerIds.add(interview.Interviewer__c);
        }

        // Query Job Applications with Candidate details
        Map<Id, Job_Application__c> appMap = new Map<Id, Job_Application__c>([
            SELECT Id, Candidate__r.First_Name__c, Candidate__r.Last_Name__c, Candidate__r.Email__c, Position__r.Name
            FROM Job_Application__c
            WHERE Id IN :jobAppIds
            WITH SECURITY_ENFORCED
        ]);

        // Query Interviewers details
        Map<Id, User> interviewerMap = new Map<Id, User>([
            SELECT Id, Name, Email
            FROM User
            WHERE Id IN :interviewerIds
            WITH SECURITY_ENFORCED
        ]);

        List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();

        for (Interview__c interview : newList) {
            Job_Application__c app = appMap.get(interview.Job_Application__c);
            User interviewer = interviewerMap.get(interview.Interviewer__c);

            if (app != null && interviewer != null) {
                String candidateName = app.Candidate__r.First_Name__c + ' ' + app.Candidate__r.Last_Name__c;
                String formattedTime = interview.Scheduled_Date_Time__c.format('yyyy-MM-dd HH:mm:ss');

                // 1. Email to Candidate
                if (String.isNotBlank(app.Candidate__r.Email__c)) {
                    Messaging.SingleEmailMessage candEmail = new Messaging.SingleEmailMessage();
                    candEmail.setToAddresses(new List<String>{app.Candidate__r.Email__c});
                    candEmail.setSubject('Interview Scheduled: ' + app.Position__r.Name);
                    candEmail.setPlainTextBody(
                        'Dear ' + candidateName + ',\n\n' +
                        'Your interview for the ' + app.Position__r.Name + ' position has been scheduled.\n\n' +
                        'Details:\n' +
                        '- Round: ' + interview.Round__c + '\n' +
                        '- Time: ' + formattedTime + '\n' +
                        '- Mode: ' + interview.Mode__c + '\n\n' +
                        'Please join using your calendar invite link.\n\n' +
                        'Best regards,\nHR Recruiting Team'
                    );
                    emailsToSend.add(candEmail);
                }

                // 2. Email to Interviewer
                if (String.isNotBlank(interviewer.Email)) {
                    Messaging.SingleEmailMessage intEmail = new Messaging.SingleEmailMessage();
                    intEmail.setToAddresses(new List<String>{interviewer.Email});
                    intEmail.setSubject('Action Required: Conduct Interview for ' + candidateName);
                    intEmail.setPlainTextBody(
                        'Hello ' + interviewer.Name + ',\n\n' +
                        'You have been assigned to conduct an interview round for ' + candidateName + '.\n\n' +
                        'Details:\n' +
                        '- Position: ' + app.Position__r.Name + '\n' +
                        '- Round: ' + interview.Round__c + '\n' +
                        '- Time: ' + formattedTime + '\n' +
                        '- Mode: ' + interview.Mode__c + '\n\n' +
                        'Please review the candidate profile and log your feedback and rating in Salesforce after completion.\n\n' +
                        'Best regards,\nHR Team'
                    );
                    emailsToSend.add(intEmail);
                }
            }
        }

        if (!emailsToSend.isEmpty()) {
            try {
                Messaging.sendEmail(emailsToSend);
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR, 'Failed to send interview email invites: ' + e.getMessage());
            }
        }
    }
}
