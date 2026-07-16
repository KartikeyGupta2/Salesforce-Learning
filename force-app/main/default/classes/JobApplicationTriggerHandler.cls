public with sharing class JobApplicationTriggerHandler {

    private static Boolean isRunning = false;

    public static void handleBeforeInsert(List<Job_Application__c> newList) {
        assignRecruiter(newList);
    }

    public static void handleAfterInsert(List<Job_Application__c> newList) {
        // Generate onboarding tasks for any record inserted directly as Joined
        Map<Id, Job_Application__c> oldMap = new Map<Id, Job_Application__c>();
        for (Job_Application__c app : newList) {
            oldMap.put(app.Id, new Job_Application__c(Id = app.Id, Status__c = 'Applied', Onboarding_Status__c = 'Not Started'));
        }
        generateOnboardingTasks(newList, oldMap);

        Set<Id> positionIds = new Set<Id>();
        for (Job_Application__c app : newList) {
            if (app.Status__c == 'Joined' && app.Position__c != null) {
                positionIds.add(app.Position__c);
            }
        }
        recalculatePositions(positionIds);
    }

    public static void handleAfterUpdate(List<Job_Application__c> newList, Map<Id, Job_Application__c> oldMap) {
        // Prevent recursion
        if (isRunning) {
            return;
        }
        isRunning = true;

        try {
            generateOnboardingTasks(newList, oldMap);
            
            Set<Id> positionIds = new Set<Id>();
            for (Job_Application__c app : newList) {
                Job_Application__c oldApp = oldMap.get(app.Id);
                if (app.Status__c != oldApp.Status__c || app.Position__c != oldApp.Position__c) {
                    if (app.Position__c != null) {
                        positionIds.add(app.Position__c);
                    }
                    if (oldApp.Position__c != null) {
                        positionIds.add(oldApp.Position__c);
                    }
                }
            }
            recalculatePositions(positionIds);
        } finally {
            isRunning = false;
        }
    }

    public static void handleAfterDelete(List<Job_Application__c> oldList) {
        Set<Id> positionIds = new Set<Id>();
        for (Job_Application__c app : oldList) {
            if (app.Status__c == 'Joined' && app.Position__c != null) {
                positionIds.add(app.Position__c);
            }
        }
        recalculatePositions(positionIds);
    }

    public static void handleAfterUndelete(List<Job_Application__c> newList) {
        Set<Id> positionIds = new Set<Id>();
        for (Job_Application__c app : newList) {
            if (app.Status__c == 'Joined' && app.Position__c != null) {
                positionIds.add(app.Position__c);
            }
        }
        recalculatePositions(positionIds);
    }

    private static void generateOnboardingTasks(List<Job_Application__c> newList, Map<Id, Job_Application__c> oldMap) {
        List<Onboarding_Task__c> tasksToCreate = new List<Onboarding_Task__c>();
        List<Job_Application__c> appsToUpdate = new List<Job_Application__c>();

        for (Job_Application__c app : newList) {
            Job_Application__c oldApp = oldMap.get(app.Id);

            // Check if status changed to "Joined"
            if (app.Status__c == 'Joined' && oldApp.Status__c != 'Joined') {
                // Check if onboarding is not already started
                if (app.Onboarding_Status__c != 'In Progress') {
                    // Prepare child Onboarding Tasks
                    tasksToCreate.add(new Onboarding_Task__c(
                        Job_Application__c = app.Id,
                        Name = 'Document Submission',
                        Type__c = 'Document Submission',
                        Status__c = 'Pending',
                        Notes__c = 'Submit educational certificates, experience letters, and signed contract.'
                    ));
                    tasksToCreate.add(new Onboarding_Task__c(
                        Job_Application__c = app.Id,
                        Name = 'System Access Setup',
                        Type__c = 'System Access',
                        Status__c = 'Pending',
                        Notes__c = 'Provision email address, Slack, and Salesforce user accounts.'
                    ));
                    tasksToCreate.add(new Onboarding_Task__c(
                        Job_Application__c = app.Id,
                        Name = 'ID Card Generation',
                        Type__c = 'ID Card',
                        Status__c = 'Pending',
                        Notes__c = 'Collect photo and print corporate ID badge.'
                    ));

                    // Queue Job Application update
                    appsToUpdate.add(new Job_Application__c(
                        Id = app.Id,
                        Onboarding_Status__c = 'In Progress'
                    ));
                }
            }
        }

        // Insert Onboarding Tasks
        if (!tasksToCreate.isEmpty() && Schema.sObjectType.Onboarding_Task__c.isCreateable()) {
            insert tasksToCreate;
        }

        // Update Job Applications for Onboarding Status
        if (!appsToUpdate.isEmpty() && Schema.sObjectType.Job_Application__c.isUpdateable()) {
            update appsToUpdate;
        }
    }

    private static void recalculatePositions(Set<Id> positionIds) {
        if (positionIds.isEmpty()) {
            return;
        }

        // Initialize Map
        Map<Id, Integer> hiredCountMap = new Map<Id, Integer>();
        for (Id posId : positionIds) {
            hiredCountMap.put(posId, 0);
        }

        // Query counts
        List<AggregateResult> results = [
            SELECT Position__c, COUNT(Id) hiredCount
            FROM Job_Application__c
            WHERE Position__c IN :positionIds AND Status__c = 'Joined'
            WITH SECURITY_ENFORCED
            GROUP BY Position__c
        ];

        for (AggregateResult ar : results) {
            Id posId = (Id)ar.get('Position__c');
            Integer count = (Integer)ar.get('hiredCount');
            hiredCountMap.put(posId, count);
        }

        // Fetch Positions to check Target Hires & update
        List<Position__c> positionsToUpdate = [
            SELECT Id, Target_Hires__c, Hired_Count__c, Status__c
            FROM Position__c
            WHERE Id IN :positionIds
            WITH SECURITY_ENFORCED
        ];

        Boolean needsUpdate = false;
        for (Position__c pos : positionsToUpdate) {
            Integer newCount = hiredCountMap.get(pos.Id);
            if (pos.Hired_Count__c != newCount) {
                pos.Hired_Count__c = newCount;
                needsUpdate = true;
            }

            // Auto-closure check
            if (pos.Hired_Count__c >= pos.Target_Hires__c && pos.Status__c != 'Closed - Filled') {
                pos.Status__c = 'Closed - Filled';
                pos.Close_Date__c = Date.today();
                needsUpdate = true;
            } else if (pos.Hired_Count__c < pos.Target_Hires__c && pos.Status__c == 'Closed - Filled') {
                pos.Status__c = 'Open - Approved';
                pos.Close_Date__c = null;
                needsUpdate = true;
            }
        }

        if (needsUpdate && Schema.sObjectType.Position__c.isUpdateable()) {
            update positionsToUpdate;
        }
    }

    private static void assignRecruiter(List<Job_Application__c> newList) {
        Set<Id> positionIds = new Set<Id>();
        for (Job_Application__c app : newList) {
            if (app.Position__c != null) {
                positionIds.add(app.Position__c);
            }
        }
        
        if (!positionIds.isEmpty()) {
            Map<Id, Position__c> positionMap = new Map<Id, Position__c>([
                SELECT Id, OwnerId, Hiring_Manager__c
                FROM Position__c
                WHERE Id IN :positionIds
                WITH SECURITY_ENFORCED
            ]);
            
            for (Job_Application__c app : newList) {
                Position__c pos = positionMap.get(app.Position__c);
                if (pos != null) {
                    if (pos.Hiring_Manager__c != null) {
                        app.OwnerId = pos.Hiring_Manager__c;
                    } else {
                        app.OwnerId = pos.OwnerId;
                    }
                }
            }
        }
    }
}
