@isTest
private class OfferTriggerTest {

    @testSetup
    static void setupTestData() {
        Account acc = new Account(Name = 'Test Corp');
        insert acc;

        Department__c dept = new Department__c(
            Name = 'Engineering',
            Account__c = acc.Id,
            Status__c = 'Active'
        );
        insert dept;

        Position__c pos = new Position__c(
            Name = 'Software Engineer',
            Status__c = 'Open - Approved',
            Target_Hires__c = 1,
            Department__c = dept.Id,
            Type__c = 'Full Time'
        );
        insert pos;

        Candidate__c cand = new Candidate__c(
            First_Name__c = 'John',
            Last_Name__c = 'Doe',
            Email__c = 'john.doe@test.com'
        );
        insert cand;

        Job_Application__c app = new Job_Application__c(
            Position__c = pos.Id,
            Candidate__c = cand.Id,
            Status__c = 'Applied'
        );
        insert app;

        Offer__c offer = new Offer__c(
            Job_Application__c = app.Id,
            Status__c = 'Draft',
            CTC__c = 100000,
            Designation__c = 'Software Engineer',
            Joining_Date__c = Date.today().addDays(30),
            Validity_Date__c = Date.today().addDays(7)
        );
        insert offer;
    }

    @isTest
    static void testOfferAccepted() {
        Offer__c offer = [SELECT Id, Status__c FROM Offer__c LIMIT 1];
        
        Test.startTest();
        offer.Status__c = 'Accepted';
        update offer;
        Test.stopTest();

        Job_Application__c app = [SELECT Status__c FROM Job_Application__c LIMIT 1];
        System.assertEquals('Joined', app.Status__c, 'Job Application status should change to Joined when Offer is Accepted');

        Position__c pos = [SELECT Hired_Count__c, Status__c FROM Position__c LIMIT 1];
        System.assertEquals(1, pos.Hired_Count__c, 'Hired count should increment');
        System.assertEquals('Closed - Filled', pos.Status__c, 'Position should auto-close when target met');
    }

    @isTest
    static void testOfferRejected() {
        // First accept the offer to close the position
        Offer__c offer = [SELECT Id, Status__c, Rejection_Reason__c FROM Offer__c LIMIT 1];
        offer.Status__c = 'Accepted';
        update offer;

        Position__c posBefore = [SELECT Status__c FROM Position__c LIMIT 1];
        System.assertEquals('Closed - Filled', posBefore.Status__c);

        Test.startTest();
        offer.Status__c = 'Rejected';
        offer.Rejection_Reason__c = 'Candidate selected another company.';
        update offer;
        Test.stopTest();

        Job_Application__c app = [SELECT Status__c, Rejection_Reason__c FROM Job_Application__c LIMIT 1];
        System.assertEquals('Rejected', app.Status__c, 'Job Application status should sync to Rejected');
        System.assertEquals('Candidate selected another company.', app.Rejection_Reason__c, 'Rejection reason should match');

        Position__c posAfter = [SELECT Status__c, Close_Date__c FROM Position__c LIMIT 1];
        System.assertEquals('Open - Approved', posAfter.Status__c, 'Position should reopen when candidate declines the offer');
        System.assertEquals(null, posAfter.Close_Date__c, 'Close date should be cleared on reopen');
    }
}
