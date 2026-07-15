import { LightningElement, wire } from 'lwc';
import getContacts from '@salesforce/apex/ContactDirectoryService.getContacts';

export default class ContactDirectory extends LightningElement {
    contacts;
    error;

    columns = [
        { label: 'First Name', fieldName: 'FirstName' },
        { label: 'Last Name', fieldName: 'LastName' },
        { label: 'Title', fieldName: 'Title' },
        { label: 'Department', fieldName: 'Department' },
        { label: 'Email', fieldName: 'Email', type: 'email' },
        { label: 'Phone', fieldName: 'Phone', type: 'phone' }
    ];

    @wire(getContacts)
    wiredContacts({ error, data }) {
        if (data) {
            this.contacts = data;
            this.error = undefined;
        } else if (error) {
            this.error = error.body.message;
            this.contacts = undefined;
        }
    }
}