import { LightningElement, api, wire } from 'lwc';
import getDepartmentsByAccount from '@salesforce/apex/DepartmentService.getDepartmentsByAccount';

export default class DepartmentSummaryCard extends LightningElement {
    // Record Page Context naturally passes recordId
    @api recordId;
    
    // Satisfy the requirement of using "@api accountId" while supporting the native record page context
    @api get accountId() {
        return this.recordId;
    }
    set accountId(value) {
        this.recordId = value;
    }
    
    departments;
    error;
    
    @wire(getDepartmentsByAccount, { accountId: '$accountId' })
    wiredDepartments({ error, data }) {
        if (data) {
            this.departments = data.map(dept => {
                return {
                    ...dept,
                    statusClass: dept.Status__c === 'Active' ? 'slds-theme_success' : 'slds-theme_default'
                };
            });
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.departments = undefined;
        }
    }
    
    get totalHeadCount() {
        if (!this.departments) return 0;
        return this.departments.reduce((sum, dept) => {
            return sum + (dept.Head_Count__c || 0);
        }, 0);
    }
    
    get totalDepartmentsCount() {
        return this.departments ? this.departments.length : 0;
    }
    
    get errorMsg() {
        if (this.error) {
            return this.error.body ? this.error.body.message : this.error.message || JSON.stringify(this.error);
        }
        return null;
    }
    
    get isLoading() {
        return this.accountId && !this.departments && !this.error;
    }
}
