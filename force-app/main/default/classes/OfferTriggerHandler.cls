public with sharing class OfferTriggerHandler {

    private static Boolean isRunning = false;

    public static void handleAfterUpdate(List<Offer__c> newList, Map<Id, Offer__c> oldMap) {
        if (isRunning) {
            return;
        }
        isRunning = true;

        try {
            syncStatusToJobApplication(newList, oldMap);
        } finally {
            isRunning = false;
        }
    }

    private static void syncStatusToJobApplication(List<Offer__c> newList, Map<Id, Offer__c> oldMap) {
        List<Job_Application__c> appsToUpdate = new List<Job_Application__c>();

        for (Offer__c offer : newList) {
            Offer__c oldOffer = oldMap.get(offer.Id);

            if (offer.Status__c != oldOffer.Status__c && offer.Job_Application__c != null) {
                String newAppStatus = null;
                String rejectionReason = null;

                if (offer.Status__c == 'Accepted') {
                    newAppStatus = 'Joined';
                } else if (offer.Status__c == 'Rejected') {
                    newAppStatus = 'Rejected';
                    rejectionReason = offer.Rejection_Reason__c;
                }

                if (newAppStatus != null) {
                    Job_Application__c app = new Job_Application__c(
                        Id = offer.Job_Application__c,
                        Status__c = newAppStatus
                    );
                    if (rejectionReason != null) {
                        app.Rejection_Reason__c = rejectionReason;
                    }
                    appsToUpdate.add(app);
                }
            }
        }

        if (!appsToUpdate.isEmpty() && Schema.sObjectType.Job_Application__c.isUpdateable()) {
            update appsToUpdate;
        }
    }
}
