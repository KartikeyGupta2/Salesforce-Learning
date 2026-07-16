trigger JobApplicationTrigger on Job_Application__c (before insert, after insert, after update, after delete, after undelete) {
    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            JobApplicationTriggerHandler.handleBeforeInsert(Trigger.new);
        }
    } else if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            JobApplicationTriggerHandler.handleAfterInsert(Trigger.new);
        } else if (Trigger.isUpdate) {
            JobApplicationTriggerHandler.handleAfterUpdate(Trigger.new, Trigger.oldMap);
        } else if (Trigger.isDelete) {
            JobApplicationTriggerHandler.handleAfterDelete(Trigger.old);
        } else if (Trigger.isUndelete) {
            JobApplicationTriggerHandler.handleAfterUndelete(Trigger.new);
        }
    }
}
