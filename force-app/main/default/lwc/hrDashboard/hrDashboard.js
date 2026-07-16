import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getDashboardStats from '@salesforce/apex/HRManagementController.getDashboardStats';
import getPendingOffers from '@salesforce/apex/HRManagementController.getPendingOffers';
import getRecentApplications from '@salesforce/apex/HRManagementController.getRecentApplications';
import getOnboardingProgress from '@salesforce/apex/HRManagementController.getOnboardingProgress';
import approveOffer from '@salesforce/apex/HRManagementController.approveOffer';
import rejectOffer from '@salesforce/apex/HRManagementController.rejectOffer';

export default class HrDashboard extends LightningElement {
    @track stats = { openPositions: 0, activeApplications: 0, pendingOffers: 0, avgInterviewRating: 0.0 };
    @track pendingOffers = [];
    @track recentApplications = [];
    @track onboardingHires = [];
    
    @track isLoading = false;
    @track error = '';

    // Modal state
    @track isRejectionModalOpen = false;
    @track rejectionReason = '';
    @track selectedOfferId = '';

    connectedCallback() {
        this.loadData();
    }

    async loadData() {
        this.isLoading = true;
        this.error = '';
        try {
            const statsData = await getDashboardStats();
            const offersData = await getPendingOffers();
            const appsData = await getRecentApplications();
            const onboardingData = await getOnboardingProgress();

            this.stats = statsData || { openPositions: 0, activeApplications: 0, pendingOffers: 0, avgInterviewRating: 0.0 };
            
            // Format Offer Names
            this.pendingOffers = (offersData || []).map(offer => ({
                ...offer,
                candidateName: offer.Job_Application__r && offer.Job_Application__r.Candidate__r 
                    ? `${offer.Job_Application__r.Candidate__r.First_Name__c} ${offer.Job_Application__r.Candidate__r.Last_Name__c}` 
                    : 'Unknown Candidate',
                positionName: offer.Job_Application__r && offer.Job_Application__r.Position__r 
                    ? offer.Job_Application__r.Position__r.Name 
                    : 'N/A'
            }));

            // Format Onboarding Hires
            this.onboardingHires = (onboardingData || []).map(onb => ({
                ...onb,
                applicationUrl: `/lightning/r/Job_Application__c/${onb.applicationId}/view`,
                progressStyle: `width: ${onb.progressPercent}%`
            }));

            // Format Recent Applications
            this.recentApplications = (appsData || []).map(app => {
                let badgeClass = 'slds-badge ';
                if (app.Status__c === 'Joined') badgeClass += 'badge-success';
                else if (app.Status__c === 'Rejected') badgeClass += 'badge-destructive';
                else if (app.Status__c === 'Interview') badgeClass += 'badge-warning';
                else badgeClass += 'badge-neutral';

                return {
                    ...app,
                    candidateName: app.Candidate__r 
                        ? `${app.Candidate__r.First_Name__c} ${app.Candidate__r.Last_Name__c}` 
                        : 'Unknown Candidate',
                    positionName: app.Position__r ? app.Position__r.Name : 'N/A',
                    applicationUrl: `/lightning/r/Job_Application__c/${app.Id}/view`,
                    badgeClass: badgeClass
                };
            });

        } catch (err) {
            console.error('Error loading dashboard data:', err);
            this.error = err.body ? err.body.message : err.message;
            this.showToast('Error', 'Failed to retrieve dashboard analytics.', 'error');
        } finally {
            this.isLoading = false;
        }
    }

    handleRefresh() {
        this.loadData();
    }

    async handleApproveOffer(event) {
        const offerId = event.target.dataset.id;
        this.isLoading = true;
        try {
            await approveOffer({ offerId });
            this.showToast('Success', 'Offer successfully approved and candidate selected.', 'success');
            await this.loadData();
        } catch (err) {
            console.error('Error approving offer:', err);
            this.showToast('Approval Failed', err.body ? err.body.message : err.message, 'error');
        } finally {
            this.isLoading = false;
        }
    }

    handlePromptReject(event) {
        this.selectedOfferId = event.target.dataset.id;
        this.rejectionReason = '';
        this.isRejectionModalOpen = true;
    }

    handleReasonChange(event) {
        this.rejectionReason = event.target.value;
    }

    handleCloseRejectionModal() {
        this.isRejectionModalOpen = false;
        this.selectedOfferId = '';
    }

    async handleConfirmRejection() {
        if (!this.rejectionReason.trim()) {
            this.showToast('Validation Error', 'A rejection reason is required.', 'warning');
            return;
        }

        const offerId = this.selectedOfferId;
        const reason = this.rejectionReason;

        this.isRejectionModalOpen = false;
        this.isLoading = true;

        try {
            await rejectOffer({ offerId, reason });
            this.showToast('Offer Rejected', 'The candidate offer has been marked as Rejected.', 'info');
            await this.loadData();
        } catch (err) {
            console.error('Error rejecting offer:', err);
            this.showToast('Rejection Failed', err.body ? err.body.message : err.message, 'error');
        } finally {
            this.isLoading = false;
            this.selectedOfferId = '';
        }
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant
            })
        );
    }

    get hasPendingOffers() {
        return this.pendingOffers.length > 0;
    }

    get hasOnboardingHires() {
        return this.onboardingHires.length > 0;
    }

    get isRejectionConfirmDisabled() {
        return !this.rejectionReason || !this.rejectionReason.trim();
    }
}
