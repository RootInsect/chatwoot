<script setup>
import EmptyState from 'dashboard/components/widgets/EmptyState.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import { computed, onMounted } from 'vue';
import { useAdmin } from 'dashboard/composables/useAdmin';
import { useMapGetter } from 'dashboard/composables/store';
import { useContactSupport } from 'dashboard/composables/useContactSupport';

const { isAdmin } = useAdmin();
const isOnChatwootCloud = useMapGetter('globalConfig/isOnChatwootCloud');
const { canContactSupport, contactSupport } = useContactSupport();

const showBillingLink = computed(
  () => isAdmin.value && isOnChatwootCloud.value
);

const toggleSupportWidgetVisibility = () => {
  if (window.$chatwoot) {
    window.$chatwoot.toggleBubbleVisibility('show');
  }
};

const setupListenerForWidgetEvent = () => {
  window.addEventListener('chatwoot:on-message', () => {
    toggleSupportWidgetVisibility();
  });
};

onMounted(() => {
  toggleSupportWidgetVisibility();
  setupListenerForWidgetEvent();
});
</script>

<template>
  <div class="items-center bg-n-slate-2 flex justify-center h-full w-full">
    <EmptyState
      class="max-w-lg"
      :title="$t('APP_GLOBAL.ACCOUNT_SUSPENDED.TITLE')"
      :message="$t('APP_GLOBAL.ACCOUNT_SUSPENDED.MESSAGE')"
    >
      <div class="flex flex-col items-center gap-3 mt-4">
        <NextButton
          v-if="canContactSupport"
          icon="i-lucide-life-buoy"
          :label="$t('SIDEBAR_ITEMS.CONTACT_SUPPORT')"
          @click="contactSupport"
        />
        <router-link
          v-if="showBillingLink"
          :to="{ name: 'billing_settings_index' }"
          class="text-sm text-n-slate-11 hover:text-n-slate-12 hover:underline"
        >
          {{ $t('APP_GLOBAL.ACCOUNT_SUSPENDED.MANAGE_BILLING') }}
        </router-link>
      </div>
    </EmptyState>
  </div>
</template>
