@isTest
private class OnboardingTaskTriggerTest {

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

        // Inserting application with Joined status will auto-create Onboarding Tasks via JobApplicationTrigger
        Job_Application__c app = new Job_Application__c(
            Position__c = pos.Id,
            Candidate__c = cand.Id,
            Status__c = 'Joined'
        );
        insert app;
    }

    @isTest
    static void testOnboardingCompletion() {
        Job_Application__c app = [SELECT Id, Onboarding_Status__c FROM Job_Application__c LIMIT 1];
        System.assertEquals('In Progress', app.Onboarding_Status__c, 'Onboarding should be In Progress initially');

        List<Onboarding_Task__c> tasks = [SELECT Id, Status__c FROM Onboarding_Task__c WHERE Job_Application__c = :app.Id];
        System.assertEquals(3, tasks.size(), 'Three onboarding tasks should have been generated');

        Test.startTest();
        for (Onboarding_Task__c task : tasks) {
            task.Status__c = 'Verified';
        }
        update tasks;
        Test.stopTest();

        Job_Application__c updatedApp = [SELECT Onboarding_Status__c FROM Job_Application__c WHERE Id = :app.Id];
        System.assertEquals('Completed', updatedApp.Onboarding_Status__c, 'Onboarding status should be Completed when all tasks are verified');
    }
}
