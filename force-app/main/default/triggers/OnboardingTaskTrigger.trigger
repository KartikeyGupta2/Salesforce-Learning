trigger OnboardingTaskTrigger on Onboarding_Task__c (after update) {
    if (Trigger.isAfter && Trigger.isUpdate) {
        OnboardingTaskTriggerHandler.handleAfterUpdate(Trigger.new, Trigger.oldMap);
    }
}
