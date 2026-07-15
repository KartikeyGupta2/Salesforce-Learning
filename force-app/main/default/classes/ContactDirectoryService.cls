public with sharing class ContactDirectoryService {
    
    @AuraEnabled(cacheable=true)
    public static List<Contact> getContacts() {
        return [SELECT Id, Name, Email, Phone, Title, Department, Account.Name
                FROM Contact
                WITH SECURITY_ENFORCED
                ORDER BY Name ASC];
    }
}