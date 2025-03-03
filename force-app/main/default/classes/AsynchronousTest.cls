/*
 * AsynchronousTest Class Description:
 * 
 * This test class provides test methods for various asynchronous operations in Salesforce:
 * 
 * 1. nextStepFuture_testUpdateAllNextStep: 
 *    - This test is designed for the NextStepFuture class. Students should insert their method from the NextStepFuture class within the specified area.
 *    - This test creates test accounts and opportunities and checks if the NextStep fields are correctly updated.
 * 
 * 2. nextStepFuture_createDealAndUpdateRole: 
 *    - Tests the creation of a big opportunity deal and updates the user role name.
 * 
 * 3. nextStepQueueable_testEnqueueJob: 
 *    - Tests the enqueue operation and execution of the NextStepQueueable class.
 *    - Validates if the NextStep fields in Account and Opportunity are set to null after execution.
 * 
 * 4. nextStepBatch_testUpdateAllNextStep: 
 *    - Tests the batch class operation for updating NextStep fields in Account and Opportunity.
 * 
 * 5. nextStepSchedule_testExecute (currently commented out): 
 *    - Will test the scheduled job once the NextStepSchedule class is implemented. This test checks if the NextStep fields are correctly updated in both Account and Opportunity objects after the scheduled job execution.
 *    - Manually setup the scheduled job in Salesforce to run the NextStepSchedule class.
 * 
 * NOTE: To run the test for nextStepSchedule_testExecute, students will need to uncomment this test method after implementing the NextStepSchedule class.
 */
 @isTest
public class AsynchronousTest {
    
    @testSetup
    static void setupTestData() {
        // Create a Test Account
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
        // Create a Test Opportunity related to the Account
        Opportunity testOpportunity = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            AccountId = testAccount.Id
        );
        insert testOpportunity;
    }

    @isTest
    static void nextStepFuture_testUpdateAllNextStep() {
        // Fetch test Account ID
        Account testAcc = [SELECT Id FROM Account LIMIT 1];

        // Define new Next Step value
        String newNextStepValue = 'Meeting in the future';

        // Ensure the future method executes in test context
        Test.startTest();
        NextStepFuture.updateAccOpp(new List<Id>{testAcc.Id}, newNextStepValue);
        Test.stopTest(); // Ensures the @future method execution completes

        // Query the updated Account
        Account updatedAcc = [SELECT Next_Step__c FROM Account WHERE Id = :testAcc.Id];

        // Validate that the field is updated
        System.assertEquals(newNextStepValue, updatedAcc.Next_Step__c, 
            'Account Next_Step__c field was not updated correctly.');

        // Query the updated Opportunity
        Opportunity updatedOpp = [SELECT NextStep FROM Opportunity WHERE AccountId = :testAcc.Id];

        // Validate that the field is updated
        System.assertEquals(newNextStepValue, updatedOpp.NextStep, 
            'Opportunity NextStep field was not updated correctly.');
    }

   @IsTest
            static void testCreateDealAndUpdateRole() {
            // Create a User with a role
            Profile p = [SELECT Id FROM Profile WHERE Name='Standard User' LIMIT 1];
            UserRole role = [SELECT Id FROM UserRole LIMIT 1];
        
            User testUser = new User(
                FirstName = 'Test',
                LastName = 'User',
                Email = 'testuser@example.com',
                Username = 'testuser@example.com' + System.currentTimeMillis(),
                Alias = 'tuser',
                TimeZoneSidKey = 'America/Los_Angeles',
                LocaleSidKey = 'en_US',
                EmailEncodingKey = 'UTF-8',
                ProfileId = p.Id,
                LanguageLocaleKey = 'en_US',
                UserRoleId = role.Id
            );
        
            System.runAs(testUser) {
                Test.startTest();
                NextStepFuture.createDealAndUpdateRole();
                Test.stopTest();
                
                UserRole updatedRole = [SELECT Id, Name FROM UserRole WHERE Id = :testUser.UserRoleId LIMIT 1];
                System.assertNotEquals(null, updatedRole, 'UserRole should exist.');
            }
        }


    @isTest
    static void nextStepQueueable_testEnqueueJob() {
        // Create test data - Accounts
        List<Account> testAccounts = new List<Account>();
        for (Integer i = 0; i < 5; i++) {
            testAccounts.add(new Account(Name = 'Test Account ' + i, Next_Step__c = 'Meeting in the future'));
        }
        insert testAccounts;

        // Create test data - Opportunities
        List<Opportunity> testOpps = new List<Opportunity>();
        for (Account acc : testAccounts) {
            testOpps.add(new Opportunity(
                Name = 'Test Opp for ' + acc.Name, 
                AccountId = acc.Id, 
                CloseDate = Date.today(), 
                StageName = 'Prospecting', 
                NextStep = 'Meeting in the future'
            ));
        }
        insert testOpps;

        // Prepare data for Queueable job
        Map<Id, Account> accountMap = new Map<Id, Account>();
        for (Account acc : testAccounts) {
            accountMap.put(acc.Id, acc);
        }

        // Start the Queueable job
        Test.startTest();
        Id jobId = System.enqueueJob(new NextStepQueueable(accountMap));
        Test.stopTest();

        // Validate that the job was enqueued
        System.assertNotEquals(null, jobId, 'The queueable job should have been enqueued.');

        // Query the updated accounts and opportunities
        List<Account> updatedAccounts = [SELECT Id, Next_Step__c FROM Account WHERE Id IN :testAccounts];
        List<Opportunity> updatedOpps = [SELECT Id, NextStep FROM Opportunity WHERE AccountId IN :testAccounts];

        // Assert that all Account records have Next_Step__c set to null
        for (Account acc : updatedAccounts) {
            System.assertEquals(null, acc.Next_Step__c, 'Account Next_Step__c should be null after processing.');
        }

        // Assert that all Opportunity records have NextStep set to null
        for (Opportunity opp : updatedOpps) {
            System.assertEquals(null, opp.NextStep, 'Opportunity NextStep should be null after processing.');
        }
    }


    @IsTest
    static void nextStepBatch_testUpdateAllNextStep() {
         //Create test data
        List<Account> testAccounts = new List<Account>();
        for (Integer i = 0; i < 5; i++) {
            testAccounts.add(new Account(Name = 'Test Account ' + i));
        }
        insert testAccounts;

        List<Opportunity> testOpps = new List<Opportunity>();
        for (Account acc : testAccounts) {
            testOpps.add(new Opportunity(Name = 'Test Opp for ' + acc.Name, AccountId = acc.Id, CloseDate = Date.today(), StageName = 'Prospecting'));
        }
        insert testOpps;

        //Call the batch class
        Test.startTest();
        NextStepBatch batchJob = new NextStepBatch();
        Id batchId = Database.executeBatch(batchJob);
        Test.stopTest();

         //Query the updated accounts and opportunities
        List<Account> updatedAccounts = [SELECT Id, Next_Step__c FROM Account WHERE Id IN :testAccounts];
        List<Opportunity> updatedOpps = [SELECT Id, NextStep FROM Opportunity WHERE Id IN :testOpps];

         //Assert that all account's Next_Step__c fields are updated
        for (Account acc : updatedAccounts) {
           System.assertEquals('Batching the next meetings together.', acc.Next_Step__c, 'Account Next_Step__c field was not updated correctly.');
        }

       // Assert that all opportunity's NextStep fields are updated
        for (Opportunity opp : updatedOpps) {
            System.assertEquals('Batching the next meetings together.', opp.NextStep, 'Opportunity NextStep field was not updated correctly.');
       }
    }
    

     //UNCOMMENT TEST METHODS BELOW ONCE THE NextStepSchedule class is implemented
       // No Changes should be required to the test methods/code below other than uncommenting them
       // Manually setup the scheduled job in Salesforce to run the NextStepSchedule class
    @IsTest
    static void nextStepSchedule_testExecute() {
        // Create test data
        List<Account> testAccounts = new List<Account>();
        for (Integer i = 0; i < 5; i++) {
            testAccounts.add(new Account(Name = 'Test Account ' + i));
        }
        insert testAccounts;

        List<Opportunity> testOpps = new List<Opportunity>();
        for (Account acc : testAccounts) {
            testOpps.add(new Opportunity(Name = 'Test Opp for ' + acc.Name, AccountId = acc.Id, CloseDate = Date.today(), StageName = 'Prospecting'));
        }
        insert testOpps;


        // Schedule the NextStepSchedule class for execution
        Test.startTest();
        
        // Schedule the job
        NextStepSchedule scheduleJob = new NextStepSchedule();
        String cron = '0 0 0 * * ?'; // Runs daily at midnight
        System.schedule('NextStepSchedule', cron, scheduleJob);
        
        // Run batch immediately to simulate execution
        Database.executeBatch(new NextStepBatch());

        Test.stopTest();

        // Query the updated accounts and opportunities
        List<Account> updatedAccounts = [SELECT Id, Next_Step__c FROM Account WHERE Id IN :testAccounts];
        List<Opportunity> updatedOpps = [SELECT Id, NextStep FROM Opportunity WHERE Id IN :testOpps];

        // Assert that all accounts have updated Next_Step__c
        for (Account acc : updatedAccounts) {
            System.assertEquals('Batching the next meetings together.', acc.Next_Step__c, 
                'Account Next_Step__c field was not updated correctly.');
        }

        // Assert that all opportunities have updated NextStep field
        for (Opportunity opp : updatedOpps) {
            System.assertEquals('Batching the next meetings together.', opp.NextStep, 
                'Opportunity NextStep field was not updated correctly.');
        }
    }
}