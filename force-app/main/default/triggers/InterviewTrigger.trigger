trigger InterviewTrigger on Interview__c (after insert) {
    if (Trigger.isAfter && Trigger.isInsert) {
        InterviewTriggerHandler.handleAfterInsert(Trigger.new);
    }
}
