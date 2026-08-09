<script>
import Banner from 'dashboard/components/ui/Banner.vue';

export default {
  components: { Banner },
  computed: {
    bannerMessage() {
      return this.$t('GENERAL_SETTINGS.PAYMENT_PENDING');
    },
    actionButtonMessage() {
      return this.$t('GENERAL_SETTINGS.OPEN_BILLING');
    },
    shouldShowBanner() {
      // Self-serve Stripe billing is disabled; do not prompt for payment updates.
      return false;
    },
  },
};
</script>

<!-- eslint-disable-next-line vue/no-root-v-if -->
<template>
  <Banner
    v-if="shouldShowBanner"
    color-scheme="alert"
    :banner-message="bannerMessage"
    :action-button-label="actionButtonMessage"
    has-action-button
  />
</template>
