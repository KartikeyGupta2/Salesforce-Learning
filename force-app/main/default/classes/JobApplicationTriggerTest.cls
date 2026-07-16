@isTest
private class JobApplicationTriggerTest {

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

        Position__c pos1 = new Position__c(
            Name = 'Software Engineer',
            Status__c = 'Open - Approved',
            Target_Hires__c = 2,
            Department__c = dept.Id,
            Type__c = 'Full Time'
        );
        Position__c pos2 = new Position__c(
            Name = 'Product Manager',
            Status__c = 'Open - Approved',
            Target_Hires__c = 1,
            Department__c = dept.Id,
            Type__c = 'Full Time'
        );
        insert new List<Position__c>{pos1, pos2};

        Candidate__c candidate = new Candidate__c(
            First_Name__c = 'John',
            Last_Name__c = 'Doe',
            Email__c = 'john.doe@test.com'
        );
        insert candidate;
    }

    @isTest
    static void testInsertRollup() {
        Position__c pos = [SELECT Id, Hired_Count__c, Status__c FROM Position__c WHERE Name = 'Software Engineer' LIMIT 1];
        Candidate__c cand = [SELECT Id FROM Candidate__c LIMIT 1];

        // Insert job application already as Joined
        Job_Application__c app = new Job_Application__c(
            Position__c = pos.Id,
            Candidate__c = cand.Id,
            Status__c = 'Joined'
        );
        
        Test.startTest();
        insert app;
        Test.stopTest();

        Position__c updatedPos = [SELECT Hired_Count__c, Status__c FROM Position__c WHERE Id = :pos.Id];
        System.assertEquals(1, updatedPos.Hired_Count__c, 'Hired count should increment on insert');
        System.assertEquals('Open - Approved', updatedPos.Status__c, 'Position should still be open as target is 2');
    }

    @isTest
    static void testUpdateRollupAndAutoClose() {
        Position__c pos = [SELECT Id, Hired_Count__c, Status__c FROM Position__c WHERE Name = 'Product Manager' LIMIT 1];
        Candidate__c cand = [SELECT Id FROM Candidate__c LIMIT 1];

        // Insert job application as Applied
        Job_Application__c app = new Job_Application__c(
            Position__c = pos.Id,
            Candidate__c = cand.Id,
            Status__c = 'Applied'
        );
        insert app;

        Position__c initialPos = [SELECT Hired_Count__c FROM Position__c WHERE Id = :pos.Id];
        System.assertEquals(0, initialPos.Hired_Count__c, 'Hired count should be 0 initially');

        Test.startTest();
        app.Status__c = 'Joined';
        update app;
        Test.stopTest();

        Position__c updatedPos = [SELECT Hired_Count__c, Status__c FROM Position__c WHERE Id = :pos.Id];
        System.assertEquals(1, updatedPos.Hired_Count__c, 'Hired count should increment to 1');
        System.assertEquals('Closed - Filled', updatedPos.Status__c, 'Position should auto-close when target of 1 is met');
    }

    @isTest
    static void testDeleteAndUndeleteRollup() {
        Position__c pos = [SELECT Id, Hired_Count__c, Status__c FROM Position__c WHERE Name = 'Software Engineer' LIMIT 1];
        Candidate__c cand = [SELECT Id FROM Candidate__c LIMIT 1];

        Job_Application__c app = new Job_Application__c(
            Position__c = pos.Id,
            Candidate__c = cand.Id,
            Status__c = 'Joined'
        );
        insert app;

        Position__c insertedPos = [SELECT Hired_Count__c FROM Position__c WHERE Id = :pos.Id];
        System.assertEquals(1, insertedPos.Hired_Count__c);

        Test.startTest();
        delete app;
        Position__c deletedPos = [SELECT Hired_Count__c FROM Position__c WHERE Id = :pos.Id];
        System.assertEquals(0, deletedPos.Hired_Count__c, 'Hired count should decrement to 0 on delete');

        undelete app;
        Test.stopTest();

        Position__c undeletedPos = [SELECT Hired_Count__c FROM Position__c WHERE Id = :pos.Id];
        System.assertEquals(1, undeletedPos.Hired_Count__c, 'Hired count should restore to 1 on undelete');
    }

    @isTest
    static void testRecruiterAssignment() {
        Position__c pos = [SELECT Id FROM Position__c WHERE Name = 'Software Engineer' LIMIT 1];
        pos.Hiring_Manager__c = UserInfo.getUserId();
        update pos;

        Candidate__c cand = [SELECT Id FROM Candidate__c LIMIT 1];

        Job_Application__c app = new Job_Application__c(
            Position__c = pos.Id,
            Candidate__c = cand.Id,
            Status__c = 'Applied'
        );

        Test.startTest();
        insert app;
        Test.stopTest();

        Job_Application__c insertedApp = [SELECT OwnerId FROM Job_Application__c WHERE Id = :app.Id];
        System.assertEquals(UserInfo.getUserId(), insertedApp.OwnerId, 'Job Application owner should be auto-assigned to the Position Hiring Manager');
    }
}
