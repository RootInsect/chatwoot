/**
 * Unified "Contact support" entry for billing, paywalls, and sidebar.
 * Prefers the configured support widget; falls back to SUPPORT_CONTACT_URL.
 */
import { computed } from 'vue';
import { useMapGetter } from 'dashboard/composables/store.js';

export function useContactSupport() {
  const globalConfig = useMapGetter('globalConfig/get');
  const currentUser = useMapGetter('getCurrentUser');

  const supportWebsiteToken = computed(() => {
    const config = globalConfig.value || {};
    return config.supportWebsiteToken || config.chatwootInboxToken || '';
  });

  const supportContactUrl = computed(() => {
    return globalConfig.value?.supportContactUrl || '';
  });

  const canContactSupport = computed(() => {
    return Boolean(
      supportWebsiteToken.value || supportContactUrl.value || window.$chatwoot
    );
  });

  const identifySupportUser = () => {
    if (!window.$chatwoot || !currentUser.value) return;

    const user = currentUser.value;
    const identifier = String(user.id);
    const payload = {
      email: user.email,
      name: user.name || user.available_name || user.email,
    };
    const identifierHash = globalConfig.value?.supportIdentifierHash;
    if (identifierHash) {
      payload.identifier_hash = identifierHash;
    }

    try {
      window.$chatwoot.setUser(identifier, payload);
    } catch (e) {
      // Widget may not be ready yet; toggle still works anonymously.
    }
  };

  const contactSupport = () => {
    if (window.$chatwoot) {
      identifySupportUser();
      window.$chatwoot.toggle();
      return true;
    }

    const url = supportContactUrl.value;
    if (url) {
      if (url.startsWith('mailto:') || url.startsWith('http')) {
        window.open(url, '_blank', 'noopener,noreferrer');
      } else {
        window.location.assign(url);
      }
      return true;
    }

    return false;
  };

  return {
    canContactSupport,
    contactSupport,
    supportContactUrl,
    supportWebsiteToken,
  };
}
