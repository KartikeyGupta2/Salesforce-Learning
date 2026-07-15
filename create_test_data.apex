// Cleanup old test data
delete [SELECT Id FROM Department__c];
delete [SELECT Id FROM Contact WHERE Email='test@acme.com'];
delete [SELECT Id FROM Account WHERE Name IN ('Acme Corp', 'Global Industries')];

Account acc1 = new Account(Name='Acme Corp');
Account acc2 = new Account(Name='Global Industries');
insert new List<Account>{acc1, acc2};

Department__c dept1 = new Department__c(
    Name = 'Engineering',
    Account__c = acc1.Id,
    Head_Count__c = 50,
    Budget__c = 1000000,
    Status__c = 'Active',
    Manager_Name__c = 'Alice Smith',
    Description__c = 'Software engineering and product development.'
);

Department__c dept2 = new Department__c(
    Name = 'Marketing',
    Account__c = acc1.Id,
    Head_Count__c = 15,
    Budget__c = 250000,
    Status__c = 'Active',
    Manager_Name__c = 'Bob Johnson',
    Description__c = 'Product marketing and corporate communications.'
);

Department__c dept3 = new Department__c(
    Name = 'Sales',
    Account__c = acc2.Id,
    Head_Count__c = 100,
    Budget__c = 2000000,
    Status__c = 'Active',
    Manager_Name__c = 'Carol Davis',
    Description__c = 'Global enterprise sales.'
);

Department__c dept4 = new Department__c(
    Name = 'Research Lab',
    Account__c = acc2.Id,
    Head_Count__c = 5,
    Budget__c = 50000,
    Status__c = 'Inactive',
    Manager_Name__c = 'David Wilson',
    Description__c = 'Experimental research facility (currently closed).'
);

insert new List<Department__c>{dept1, dept2, dept3, dept4};

// We will also just insert one contact for testing the ContactDirectory
Contact c1 = new Contact(FirstName='Test', LastName='Contact', AccountId=acc1.Id, Title='Developer', Department='Engineering', Email='test@acme.com', Phone='555-1234');
insert c1;

System.debug('Test Data created successfully.');
