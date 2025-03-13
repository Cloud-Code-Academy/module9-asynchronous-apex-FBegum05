/*
 * NextStepFuture Class Description:
 * 
 * Question 1: Create a future method that updates all account and opportunities next step to 'Meeting in the future'
 * Question 2: Create a method that inserts a big deal opportunity and updates the user role name to 'CRO'
 * 
 * Benefits of using future methods:
 * 
 * 1. Asynchronous Processing: Allows long-running operations to be handled in the background, freeing up resources.
 * 2. Governor Limit Management: Asynchronous methods have a separate set of limits, providing more flexibility.
 * 3. User Experience Enhancement: Improves responsiveness in user interfaces by offloading processes to the background.
 * 4. Mixed DML Operations Handling: Helps overcome Mixed DML errors by allowing updates on setup and non-setup objects.
 * 5. Enhanced Integration Capabilities: Useful for making callouts to external systems without blocking the user interaction.
 * 
 * For more detailed information, refer to the official Salesforce documentation: https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_invoking_future_methods.htm
 * 
 * Note: The class below contains placeholders for implementing a future method to update accounts and opportunities.
 *       The accompanying test class 'AsynchronousTest' should also be updated to test this method.
 */
public with sharing class NextStepFuture {

    /* 
     * Question 1
     * Update/Uncomment the template code to create a method
     * Create a future method that updates all account and opportunities next step to 'Meeting in the future'
     * Account Next Step field is a custom field
     * Opportunity Next Step field is a standard field
     * Update the corresponding test class AsynchronousTest and test method nextStepFuture_testUpdateAllNextStep to cover test this method
     */
    //[public | private ] [static] data_type method_name (input parameters) {
    //  The body of the method
    //
    
    
    @future
    public static void updateAccOpp(List<Id> accIds, String newNextStepField) {
        // Query and update Accounts
        List<Account> accountsToUpdate = [SELECT Id, Next_Step__c FROM Account WHERE Id IN :accIds];
        if (!accountsToUpdate.isEmpty()) {
            for (Account acc : accountsToUpdate) {
                acc.Next_Step__c = newNextStepField;
            }
            update accountsToUpdate;
        }

        // Query and update Opportunities related to those Accounts
        List<Opportunity> opportunitiesToUpdate = [SELECT Id, NextStep FROM Opportunity WHERE AccountId IN :accIds];
        if (!opportunitiesToUpdate.isEmpty()) {
            for (Opportunity opp : opportunitiesToUpdate) {
                opp.NextStep = newNextStepField;
            }
            update opportunitiesToUpdate;
        }
    }
    public static void createDealAndUpdateRole(){
        Opportunity bigDeal = new Opportunity(
            Name = 'Big Deal',
            Amount = 1000000,
            Stagename = 'Closed Won',
            CloseDate = Date.today()
        
        );
        insert bigDeal;
        updateUserRoleFuture(UserInfo.getUserRoleId());
        
    }
    @future
    public static void  updateUserRoleFuture(Id userRoleId){
        try{
            UserRole[] roles = [SELECT Id,Name FROM UserRole WHERE Id =:userRoleId LIMIT 1];
            if(!roles.isEmpty()){
                UserRole role =roles[0];
                role.Name ='CRO';
                update role;
            }
        }
        catch(Exception e){
            System.debug('Error in updateUserRoleFuture:' +e.getMessage());
        }
    }
}
