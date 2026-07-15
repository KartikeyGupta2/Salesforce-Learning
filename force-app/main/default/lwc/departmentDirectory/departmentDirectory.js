import { LightningElement, track, wire } from 'lwc';
import getDepartments from '@salesforce/apex/DepartmentService.getDepartments';
import getAllDepartments from '@salesforce/apex/DepartmentService.getAllDepartments';

export default class DepartmentDirectory extends LightningElement {
    @track showActiveOnly = true;
    
    activeDepartments;
    allDepartments;
    activeError;
    allError;
    
    @wire(getDepartments)
    wiredActive({ error, data }) {
        if (data) {
            this.activeDepartments = data.map(dept => this.formatDepartment(dept));
            this.activeError = undefined;
        } else if (error) {
            this.activeError = error;
            this.activeDepartments = undefined;
        }
    }
    
    @wire(getAllDepartments)
    wiredAll({ error, data }) {
        if (data) {
            this.allDepartments = data.map(dept => this.formatDepartment(dept));
            this.allError = undefined;
        } else if (error) {
            this.allError = error;
            this.allDepartments = undefined;
        }
    }
    
    formatDepartment(dept) {
        return {
            ...dept,
            accountName: dept.Account__r ? dept.Account__r.Name : 'N/A',
            formattedBudget: dept.Budget__c ? new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' }).format(dept.Budget__c) : 'N/A',
            statusClass: dept.Status__c === 'Active' ? 'slds-theme_success' : 'slds-theme_default'
        };
    }
    
    get departments() {
        return this.showActiveOnly ? this.activeDepartments : this.allDepartments;
    }
    
    get error() {
        return this.showActiveOnly ? this.activeError : this.allError;
    }
    
    get errorMsg() {
        let err = this.error;
        if (err) {
            return err.body ? err.body.message : err.message || JSON.stringify(err);
        }
        return null;
    }
    
    get isLoading() {
        return !this.departments && !this.error;
    }
    
    get toggleButtonLabel() {
        return this.showActiveOnly ? 'Show All' : 'Active Only';
    }
    
    handleToggle() {
        this.showActiveOnly = !this.showActiveOnly;
    }
}
