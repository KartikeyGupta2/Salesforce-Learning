@isTest
private class HRManagementControllerTest {

    @testSetup
    static void setupTestData() {
        // Create test Account
        Account acc = new Account(Name = 'Test Corp');
        insert acc;

        // Create test Department
        Department__c dept = new Department__c(
            Name = 'Engineering',
            Account__c = acc.Id,
            Head_Count__c = 10,
            Budget__c = 100000,
            Status__c = 'Active',
            Manager_Name__c = 'Test Manager'
        );
        insert dept;

        // Create test Position
        Position__c pos = new Position__c(
            Name = 'Software Engineer',
            Status__c = 'Open - Approved',
            Target_Hires__c = 2,
            Hiring_Manager__c = UserInfo.getUserId(),
            Location__c = 'San Francisco, CA',
            Type__c = 'Full Time'
        );
        insert pos;

        // Create test Candidate
        Candidate__c cand = new Candidate__c(
            First_Name__c = 'John',
            Last_Name__c = 'Doe',
            Email__c = 'john.doe@test.com',
            Phone__c = '555-1234'
        );
        insert cand;

        // Create test Job Application
        Job_Application__c app = new Job_Application__c(
            Candidate__c = cand.Id,
            Position__c = pos.Id,
            Status__c = 'Interview',
            Onboarding_Status__c = 'In Progress',
            Orientation_Date__c = Date.today().addDays(7)
        );
        insert app;

        // Create test Interview
        Interview__c interview1 = new Interview__c(
            Job_Application__c = app.Id,
            Interviewer__c = UserInfo.getUserId(),
            Round__c = 'HR Round',
            Scheduled_Date_Time__c = DateTime.now().addDays(-1),
            Status__c = 'Completed',
            Rating__c = 'Strong Yes',
            Feedback__c = 'Excellent communication skills.'
        );
        insert interview1;

        // Create test Offer
        Offer__c offer = new Offer__c(
            Job_Application__c = app.Id,
            Designation__c = 'Software Engineer',
            CTC__c = 120000,
            Joining_Date__c = Date.today().addDays(14),
            Validity_Date__c = Date.today().addDays(7),
            Status__c = 'Pending Approval',
            Probation_Period_Months__c = 3
        );
        insert offer;

        // Create test Onboarding Task
        Onboarding_Task__c task = new Onboarding_Task__c(
            Job_Application__c = app.Id,
            Name = 'Document Submission',
            Type__c = 'Document Submission',
            Status__c = 'Pending'
        );
        insert task;
    }

    @isTest
    static void testGetDashboardStats() {
        Test.startTest();
        HRManagementController.DashboardStats stats = HRManagementController.getDashboardStats();
        Test.stopTest();

        System.assertNotEquals(null, stats, 'Stats wrapper should not be null');
        System.assertEquals(1, stats.openPositions, 'Should have 1 open position');
        System.assertEquals(1, stats.activeApplications, 'Should have 1 active application');
        System.assertEquals(1, stats.pendingOffers, 'Should have 1 pending offer');
        System.assertEquals(1, stats.activeOnboardings, 'Should have 1 active onboarding');
        System.assertEquals(4.0, stats.avgInterviewRating, 'Should compute average score correctly');
    }

    @isTest
    static void testGetPendingOffers() {
        Test.startTest();
        List<Offer__c> pendingOffers = HRManagementController.getPendingOffers();
        Test.stopTest();

        System.assertEquals(1, pendingOffers.size(), 'Should find 1 pending offer');
        System.assertEquals('Software Engineer', pendingOffers[0].Designation__c, 'Designation should match');
    }

    @isTest
    static void testGetRecentApplications() {
        Test.startTest();
        List<Job_Application__c> recentApps = HRManagementController.getRecentApplications();
        Test.stopTest();

        System.assertEquals(1, recentApps.size(), 'Should find 1 recent application');
    }

    @isTest
    static void testGetOnboardingProgress() {
        Test.startTest();
        List<HRManagementController.OnboardingProgressWrapper> progress = HRManagementController.getOnboardingProgress();
        Test.stopTest();

        System.assertEquals(1, progress.size(), 'Should find 1 active onboarding');
        System.assertEquals('John Doe', progress[0].candidateName, 'Candidate name should match');
        System.assertEquals(1, progress[0].totalTasks, 'Should count 1 onboarding task total');
        System.assertEquals(0, progress[0].verifiedTasks, 'Should count 0 verified onboarding tasks');
        System.assertEquals(0, progress[0].progressPercent, 'Progress percent should be 0%');
    }

    @isTest
    static void testApproveOffer() {
        Offer__c offer = [SELECT Id FROM Offer__c LIMIT 1];

        Test.startTest();
        HRManagementController.approveOffer(offer.Id);
        Test.stopTest();

        Offer__c updatedOffer = [SELECT Id, Status__c FROM Offer__c WHERE Id = :offer.Id];
        System.assertEquals('Approved', updatedOffer.Status__c, 'Offer should be marked as Approved');

        Job_Application__c app = [SELECT Id, Status__c FROM Job_Application__c LIMIT 1];
        System.assertEquals('Selected', app.Status__c, 'Job Application should be marked as Selected');
    }

    @isTest
    static void testRejectOffer() {
        Offer__c offer = [SELECT Id FROM Offer__c LIMIT 1];

        Test.startTest();
        HRManagementController.rejectOffer(offer.Id, 'Candidate declined the salary terms.');
        Test.stopTest();

        Offer__c updatedOffer = [SELECT Id, Status__c, Rejection_Reason__c FROM Offer__c WHERE Id = :offer.Id];
        System.assertEquals('Rejected', updatedOffer.Status__c, 'Offer should be marked as Rejected');
        System.assertEquals('Candidate declined the salary terms.', updatedOffer.Rejection_Reason__c, 'Rejection reason should be recorded');

        Job_Application__c app = [SELECT Id, Status__c, Rejection_Reason__c FROM Job_Application__c LIMIT 1];
        System.assertEquals('Rejected', app.Status__c, 'Job Application should be marked as Rejected');
        System.assertEquals('Candidate declined the salary terms.', app.Rejection_Reason__c, 'Rejection reason should match on Job Application');
    }

    @isTest
    static void testRejectOfferNegative() {
        Offer__c offer = [SELECT Id FROM Offer__c LIMIT 1];

        Test.startTest();
        try {
            HRManagementController.rejectOffer(offer.Id, '');
            System.assert(false, 'Should have thrown exception for empty reason');
        } catch (AuraHandledException e) {
            System.assertEquals('Script-thrown exception', e.getMessage(), 'Should fail on blank reason validation');
        }
        Test.stopTest();
    }

    @isTest
    static void testClonePosition() {
        Position__c original = [SELECT Id, Name, Type__c FROM Position__c LIMIT 1];
        
        Test.startTest();
        Id clonedId = HRManagementController.clonePosition(original.Id);
        Test.stopTest();

        System.assertNotEquals(null, clonedId, 'Cloned position ID should not be null');
        Position__c cloned = [
            SELECT Name, Type__c, Status__c, Open_Date__c, Close_Date__c, Hire_By__c, Hired_Count__c
            FROM Position__c
            WHERE Id = :clonedId
        ];
        System.assertEquals(original.Name, cloned.Name, 'Name should be cloned');
        System.assertEquals(original.Type__c, cloned.Type__c, 'Type should be cloned');
        System.assertEquals('New Position', cloned.Status__c, 'Status should default to New Position');
        System.assertEquals(null, cloned.Open_Date__c, 'Open Date should be cleared');
        System.assertEquals(null, cloned.Close_Date__c, 'Close Date should be cleared');
        System.assertEquals(null, cloned.Hire_By__c, 'Hire By should be cleared');
        System.assertEquals(0, cloned.Hired_Count__c, 'Hired count should be 0');
    }

    @isTest
    static void testClonePositionNull() {
        Test.startTest();
        try {
            HRManagementController.clonePosition(null);
            System.assert(false, 'Should throw exception on null ID');
        } catch (AuraHandledException e) {
            System.assertEquals('Script-thrown exception', e.getMessage());
        }
        Test.stopTest();
    }
}
