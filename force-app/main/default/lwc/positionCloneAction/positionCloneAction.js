import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import clonePosition from '@salesforce/apex/HRManagementController.clonePosition';

export default class PositionCloneAction extends NavigationMixin(LightningElement) {
    @api recordId;

    @api invoke() {
        if (!this.recordId) {
            return;
        }

        clonePosition({ positionId: this.recordId })
            .then((clonedId) => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Position cloned successfully!',
                        variant: 'success'
                    })
                );
                // Navigate to the cloned record
                this[NavigationMixin.Navigate]({
                    type: 'standard__recordPage',
                    attributes: {
                        recordId: clonedId,
                        objectApiName: 'Position__c',
                        actionName: 'view'
                    }
                });
            })
            .catch((error) => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error cloning position',
                        message: error.body ? error.body.message : error.message,
                        variant: 'error',
                        mode: 'sticky'
                    })
                );
            });
    }
}
