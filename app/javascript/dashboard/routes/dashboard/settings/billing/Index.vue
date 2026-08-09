<script setup>
import { computed, onMounted } from 'vue';
import { useRouter } from 'vue-router';
import { useMapGetter, useStore } from 'dashboard/composables/store.js';
import { useAccount } from 'dashboard/composables/useAccount';
import { useCaptain } from 'dashboard/composables/useCaptain';
import { useContactSupport } from 'dashboard/composables/useContactSupport';

import BillingMeter from './components/BillingMeter.vue';
import BillingCard from './components/BillingCard.vue';
import BillingHeader from './components/BillingHeader.vue';
import DetailItem from './components/DetailItem.vue';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import SettingsLayout from '../SettingsLayout.vue';
import ButtonV4 from 'next/button/Button.vue';

const router = useRouter();
const { currentAccount, isOnChatwootCloud } = useAccount();
const {
  captainEnabled,
  captainLimits,
  documentLimits,
  responseLimits,
  fetchLimits,
  isFetchingLimits,
} = useCaptain();

const uiFlags = useMapGetter('accounts/getUIFlags');
const store = useStore();
const { contactSupport } = useContactSupport();

const customAttributes = computed(() => {
  return currentAccount.value.custom_attributes || {};
});

const planName = computed(() => {
  return customAttributes.value.plan_name;
});

const subscribedQuantity = computed(() => {
  return customAttributes.value.subscribed_quantity;
});

const onContactSupport = () => {
  contactSupport();
};

onMounted(() => {
  if (!isOnChatwootCloud.value) {
    router.push({ name: 'home' });
    return;
  }

  store.dispatch('accounts/limits');
  fetchLimits();
});
</script>

<template>
  <SettingsLayout :is-loading="uiFlags.isFetchingItem">
    <template #header>
      <BaseSettingsHeader
        :title="$t('BILLING_SETTINGS.TITLE')"
        :description="$t('BILLING_SETTINGS.DESCRIPTION')"
      />
    </template>
    <template #body>
      <section class="grid gap-4">
        <BillingCard
          :title="$t('BILLING_SETTINGS.MANAGE_SUBSCRIPTION.TITLE')"
          :description="$t('BILLING_SETTINGS.MANAGE_SUBSCRIPTION.DESCRIPTION')"
        >
          <template #action>
            <ButtonV4
              sm
              solid
              blue
              icon="i-lucide-life-buoy"
              @click="onContactSupport"
            >
              {{ $t('BILLING_SETTINGS.MANAGE_SUBSCRIPTION.BUTTON_TXT') }}
            </ButtonV4>
          </template>
          <div
            v-if="planName || subscribedQuantity"
            class="grid lg:grid-cols-4 sm:grid-cols-3 grid-cols-1 gap-2 divide-x divide-n-weak"
          >
            <DetailItem
              :label="$t('BILLING_SETTINGS.CURRENT_PLAN.TITLE')"
              :value="planName"
            />
            <DetailItem
              v-if="subscribedQuantity"
              :label="$t('BILLING_SETTINGS.CURRENT_PLAN.SEAT_COUNT')"
              :value="subscribedQuantity"
            />
          </div>
        </BillingCard>

        <BillingCard
          v-if="captainEnabled"
          :title="$t('BILLING_SETTINGS.CAPTAIN.TITLE')"
          :description="$t('BILLING_SETTINGS.CAPTAIN.DESCRIPTION')"
        >
          <template #action>
            <div class="flex gap-2">
              <ButtonV4
                sm
                flushed
                slate
                icon="i-lucide-refresh-cw"
                :is-loading="isFetchingLimits"
                @click="fetchLimits"
              >
                {{ $t('BILLING_SETTINGS.CAPTAIN.REFRESH_CREDITS') }}
              </ButtonV4>
              <ButtonV4
                sm
                solid
                blue
                icon="i-lucide-life-buoy"
                @click="onContactSupport"
              >
                {{ $t('BILLING_SETTINGS.CAPTAIN.BUTTON_TXT') }}
              </ButtonV4>
            </div>
          </template>
          <div v-if="captainLimits && responseLimits" class="px-5">
            <BillingMeter
              :title="$t('BILLING_SETTINGS.CAPTAIN.RESPONSES')"
              v-bind="responseLimits"
            />
          </div>
          <div v-if="captainLimits && documentLimits" class="px-5">
            <BillingMeter
              :title="$t('BILLING_SETTINGS.CAPTAIN.DOCUMENTS')"
              v-bind="documentLimits"
            />
          </div>
        </BillingCard>
        <BillingCard
          v-else
          :title="$t('BILLING_SETTINGS.CAPTAIN.TITLE')"
          :description="$t('BILLING_SETTINGS.CAPTAIN.UPGRADE')"
        >
          <template #action>
            <ButtonV4
              sm
              solid
              blue
              icon="i-lucide-life-buoy"
              @click="onContactSupport"
            >
              {{ $t('BILLING_SETTINGS.MANAGE_SUBSCRIPTION.BUTTON_TXT') }}
            </ButtonV4>
          </template>
        </BillingCard>

        <BillingHeader
          class="px-1 mt-5"
          :title="$t('BILLING_SETTINGS.CHAT_WITH_US.TITLE')"
          :description="$t('BILLING_SETTINGS.CHAT_WITH_US.DESCRIPTION')"
        >
          <ButtonV4
            sm
            solid
            slate
            icon="i-lucide-life-buoy"
            @click="onContactSupport"
          >
            {{ $t('BILLING_SETTINGS.CHAT_WITH_US.BUTTON_TXT') }}
          </ButtonV4>
        </BillingHeader>
      </section>
    </template>
  </SettingsLayout>
</template>
