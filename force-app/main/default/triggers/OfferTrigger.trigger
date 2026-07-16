trigger OfferTrigger on Offer__c (after update) {
    if (Trigger.isAfter && Trigger.isUpdate) {
        OfferTriggerHandler.handleAfterUpdate(Trigger.new, Trigger.oldMap);
    }
}
