public with sharing class DepartmentService {
    
    @AuraEnabled(cacheable=true)
    public static List<Department__c> getDepartments() {
        return [SELECT Id, Name, Manager_Name__c, Head_Count__c, Budget__c, Status__c, Account__r.Name
                FROM Department__c
                WHERE Status__c = 'Active'
                WITH SECURITY_ENFORCED
                ORDER BY Name ASC];
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Department__c> getAllDepartments() {
        return [SELECT Id, Name, Manager_Name__c, Head_Count__c, Budget__c, Status__c, Account__r.Name
                FROM Department__c
                WITH SECURITY_ENFORCED
                ORDER BY Name ASC];
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Department__c> getDepartmentsByAccount(Id accountId) {
        return [SELECT Id, Name, Manager_Name__c, Head_Count__c, Status__c
                FROM Department__c
                WHERE Account__c = :accountId
                WITH SECURITY_ENFORCED];
    }
}