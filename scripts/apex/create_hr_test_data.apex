// HR Management System Demo Data Setup
System.debug('Cleaning up old HR demo records...');
delete [SELECT Id FROM Onboarding_Task__c];
delete [SELECT Id FROM Offer__c];
delete [SELECT Id FROM Interview__c];
delete [SELECT Id FROM Job_Application__c WHERE Status__c IN ('Applied', 'Screening', 'Shortlisted', 'Interview', 'Selected', 'Offer Sent', 'Joined')];
delete [SELECT Id FROM Candidate__c WHERE Email__c IN ('alice.brown@demo.com', 'bob.miller@demo.com', 'charlie.davis@demo.com', 'dan.green@demo.com')];
delete [SELECT Id FROM Position__c WHERE Name IN ('Senior Software Architect', 'QA Automation Lead', 'HR Specialist')];
delete [SELECT Id FROM Department__c WHERE Name IN ('Engineering R&D', 'Quality Assurance')];
delete [SELECT Id FROM Account WHERE Name = 'Acme HR Corporation'];

System.debug('Creating new HR demo records...');

// 1. Create Account
Account acc = new Account(Name = 'Acme HR Corporation');
insert acc;

// 2. Create Departments
Department__c engDept = new Department__c(
    Name = 'Engineering R&D',
    Account__c = acc.Id,
    Head_Count__c = 45,
    Budget__c = 1500000,
    Status__c = 'Active',
    Manager_Name__c = 'Alice Smith',
    Department_Head__c = UserInfo.getUserId()
);
Department__c qaDept = new Department__c(
    Name = 'Quality Assurance',
    Account__c = acc.Id,
    Head_Count__c = 15,
    Budget__c = 400000,
    Status__c = 'Active',
    Manager_Name__c = 'Carol Davis',
    Department_Head__c = UserInfo.getUserId()
);
insert new List<Department__c>{engDept, qaDept};

// 3. Create Positions
Position__c pos1 = new Position__c(
    Name = 'Senior Software Architect',
    Department__c = engDept.Id,
    Status__c = 'Open - Approved',
    Target_Hires__c = 2,
    Hiring_Manager__c = UserInfo.getUserId(),
    Location__c = 'San Francisco, CA',
    Type__c = 'Full Time',
    Min_Pay__c = 120000,
    Max_Pay__c = 180000,
    Job_Description__c = 'Responsible for leading structural architecture design of Cloud Applications.'
);
Position__c pos2 = new Position__c(
    Name = 'QA Automation Lead',
    Department__c = qaDept.Id,
    Status__c = 'Open - Approved',
    Target_Hires__c = 1,
    Hiring_Manager__c = UserInfo.getUserId(),
    Location__c = 'Austin, TX',
    Type__c = 'Full Time',
    Min_Pay__c = 90000,
    Max_Pay__c = 130000,
    Job_Description__c = 'Lead technical test automation and write robust regression test suites.'
);
insert new List<Position__c>{pos1, pos2};

// 4. Create Candidates
Candidate__c cand1 = new Candidate__c(
    First_Name__c = 'Alice',
    Last_Name__c = 'Brown',
    Email__c = 'alice.brown@demo.com',
    Phone__c = '555-0101',
    Street__c = '100 Pine St',
    City__c = 'San Francisco',
    State_Province__c = 'CA',
    Country__c = 'USA'
);
Candidate__c cand2 = new Candidate__c(
    First_Name__c = 'Bob',
    Last_Name__c = 'Miller',
    Email__c = 'bob.miller@demo.com',
    Phone__c = '555-0102',
    Street__c = '200 Oak Ave',
    City__c = 'Austin',
    State_Province__c = 'TX',
    Country__c = 'USA'
);
Candidate__c cand3 = new Candidate__c(
    First_Name__c = 'Charlie',
    Last_Name__c = 'Davis',
    Email__c = 'charlie.davis@demo.com',
    Phone__c = '555-0103',
    Street__c = '300 Elm Rd',
    City__c = 'Seattle',
    State_Province__c = 'WA',
    Country__c = 'USA'
);
Candidate__c cand4 = new Candidate__c(
    First_Name__c = 'Dan',
    Last_Name__c = 'Green',
    Email__c = 'dan.green@demo.com',
    Phone__c = '555-0104',
    Street__c = '400 Maple Dr',
    City__c = 'Boston',
    State_Province__c = 'MA',
    Country__c = 'USA'
);
insert new List<Candidate__c>{cand1, cand2, cand3, cand4};

// 5. Create Job Applications
Job_Application__c app1 = new Job_Application__c(
    Candidate__c = cand1.Id,
    Position__c = pos1.Id,
    Status__c = 'Interview'
);
Job_Application__c app2 = new Job_Application__c(
    Candidate__c = cand2.Id,
    Position__c = pos1.Id,
    Status__c = 'Joined',
    Onboarding_Buddy__c = UserInfo.getUserId(),
    Orientation_Date__c = Date.today().addDays(5)
);
Job_Application__c app3 = new Job_Application__c(
    Candidate__c = cand3.Id,
    Position__c = pos2.Id,
    Status__c = 'Screening'
);
Job_Application__c app4 = new Job_Application__c(
    Candidate__c = cand4.Id,
    Position__c = pos2.Id,
    Status__c = 'Offer Sent'
);
insert new List<Job_Application__c>{app1, app2, app3, app4};

// 6. Create Completed & Scheduled Interviews
Interview__c int1 = new Interview__c(
    Job_Application__c = app1.Id,
    Interviewer__c = UserInfo.getUserId(),
    Round__c = 'HR Round',
    Scheduled_Date_Time__c = DateTime.now().addDays(-2),
    Status__c = 'Completed',
    Rating__c = 'Strong Yes',
    Feedback__c = 'Outstanding candidate. Strong cultural fit and excellent communication.'
);
Interview__c int2 = new Interview__c(
    Job_Application__c = app1.Id,
    Interviewer__c = UserInfo.getUserId(),
    Round__c = 'Technical Round',
    Scheduled_Date_Time__c = DateTime.now().addDays(2),
    Status__c = 'Scheduled',
    Mode__c = 'Video Call'
);
Interview__c int3 = new Interview__c(
    Job_Application__c = app3.Id,
    Interviewer__c = UserInfo.getUserId(),
    Round__c = 'HR Round',
    Scheduled_Date_Time__c = DateTime.now().addDays(-1),
    Status__c = 'Completed',
    Rating__c = 'Yes',
    Feedback__c = 'Qualified candidate, ready for technical screening.'
);
insert new List<Interview__c>{int1, int2, int3};

// 7. Create Offers (One pending, one accepted)
Offer__c off1 = new Offer__c(
    Job_Application__c = app1.Id,
    Designation__c = 'Senior Software Architect',
    CTC__c = 155000,
    Joining_Date__c = Date.today().addDays(30),
    Validity_Date__c = Date.today().addDays(7),
    Status__c = 'Pending Approval',
    Probation_Period_Months__c = 3,
    Benefits__c = 'Full health insurance, 401(k) match, and stock options eligibility.'
);
Offer__c off2 = new Offer__c(
    Job_Application__c = app2.Id,
    Designation__c = 'Senior Software Architect',
    CTC__c = 150000,
    Joining_Date__c = Date.today().addDays(15),
    Validity_Date__c = Date.today().addDays(5),
    Status__c = 'Accepted',
    Probation_Period_Months__c = 3,
    Benefits__c = 'Full health insurance and 401(k) matching.'
);
insert new List<Offer__c>{off1, off2};

// 8. Create Onboarding Tasks (Some pending, some verified)
Onboarding_Task__c t1 = new Onboarding_Task__c(
    Job_Application__c = app2.Id,
    Name = 'Document Submission',
    Type__c = 'Document Submission',
    Status__c = 'Verified',
    Notes__c = 'All certificates and previous salary slip verified.'
);
Onboarding_Task__c t2 = new Onboarding_Task__c(
    Job_Application__c = app2.Id,
    Name = 'System Access Setup',
    Type__c = 'System Access',
    Status__c = 'Pending',
    Notes__c = 'Active Directory credentials sent to candidate personal email.'
);
Onboarding_Task__c t3 = new Onboarding_Task__c(
    Job_Application__c = app2.Id,
    Name = 'ID Card Generation',
    Type__c = 'ID Card',
    Status__c = 'Pending',
    Notes__c = 'Photo collection pending.'
);
insert new List<Onboarding_Task__c>{t1, t2, t3};

System.debug('HR Management System Demo Data loaded successfully.');
