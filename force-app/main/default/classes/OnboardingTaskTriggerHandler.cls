public with sharing class OnboardingTaskTriggerHandler {

    private static Boolean isRunning = false;

    public static void handleAfterUpdate(List<Onboarding_Task__c> newList, Map<Id, Onboarding_Task__c> oldMap) {
        if (isRunning) {
            return;
        }
        isRunning = true;

        try {
            checkOnboardingCompletion(newList, oldMap);
        } finally {
            isRunning = false;
        }
    }

    private static void checkOnboardingCompletion(List<Onboarding_Task__c> newList, Map<Id, Onboarding_Task__c> oldMap) {
        Set<Id> jobAppIdsToCheck = new Set<Id>();

        for (Onboarding_Task__c task : newList) {
            Onboarding_Task__c oldTask = oldMap.get(task.Id);
            if (task.Status__c == 'Verified' && oldTask.Status__c != 'Verified') {
                jobAppIdsToCheck.add(task.Job_Application__c);
            }
        }

        if (!jobAppIdsToCheck.isEmpty()) {
            List<Job_Application__c> appsToUpdate = new List<Job_Application__c>();
            
            // Query Job Applications and all child Onboarding Tasks in one query
            List<Job_Application__c> apps = [SELECT Id, Onboarding_Status__c,
                                                    (SELECT Id, Status__c FROM Onboarding_Tasks__r)
                                             FROM Job_Application__c
                                             WHERE Id IN :jobAppIdsToCheck
                                             WITH SECURITY_ENFORCED];

            for (Job_Application__c app : apps) {
                Boolean allVerified = true;
                if (app.Onboarding_Tasks__r.isEmpty()) {
                    allVerified = false;
                } else {
                    for (Onboarding_Task__c task : app.Onboarding_Tasks__r) {
                        if (task.Status__c != 'Verified') {
                            allVerified = false;
                            break;
                        }
                    }
                }

                if (allVerified && app.Onboarding_Status__c != 'Completed') {
                    app.Onboarding_Status__c = 'Completed';
                    appsToUpdate.add(new Job_Application__c(
                        Id = app.Id,
                        Onboarding_Status__c = 'Completed'
                    ));
                }
            }

            if (!appsToUpdate.isEmpty() && Schema.sObjectType.Job_Application__c.isUpdateable()) {
                update appsToUpdate;
            }
        }
    }
}
