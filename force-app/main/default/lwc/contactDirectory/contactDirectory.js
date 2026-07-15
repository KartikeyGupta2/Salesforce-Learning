import { LightningElement, track, wire } from 'lwc';
import getContacts from '@salesforce/apex/ContactDirectoryService.getContacts';

export default class ContactDirectory extends LightningElement {
    @track searchText = '';
    
    contacts;
    error;
    
    @wire(getContacts)
    wiredContacts({ error, data }) {
        if (data) {
            this.contacts = data.map(contact => {
                let titleDeptText = '';
                if (contact.Title && contact.Department) {
                    titleDeptText = `${contact.Title} - ${contact.Department}`;
                } else if (contact.Title) {
                    titleDeptText = contact.Title;
                } else if (contact.Department) {
                    titleDeptText = contact.Department;
                }
                
                return {
                    ...contact,
                    accountName: contact.Account ? contact.Account.Name : 'N/A',
                    hasTitleOrDept: !!titleDeptText,
                    titleDeptText: titleDeptText,
                    mailtoLink: contact.Email ? `mailto:${contact.Email}` : '',
                    telLink: contact.Phone ? `tel:${contact.Phone}` : ''
                };
            });
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.contacts = undefined;
        }
    }
    
    handleSearchChange(event) {
        this.searchText = event.target.value.toLowerCase();
    }
    
    get filteredContacts() {
        if (!this.contacts) {
            return null;
        }
        
        if (!this.searchText) {
            return this.contacts;
        }
        
        return this.contacts.filter(contact => 
            contact.Name.toLowerCase().includes(this.searchText)
        );
    }
    
    get contactCount() {
        return this.filteredContacts ? this.filteredContacts.length : 0;
    }
    
    get errorMsg() {
        if (this.error) {
            return this.error.body ? this.error.body.message : this.error.message || JSON.stringify(this.error);
        }
        return null;
    }
    
    get isLoading() {
        return !this.contacts && !this.error;
    }
}