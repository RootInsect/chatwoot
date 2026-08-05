# frozen_string_literal: true

# Applies temporary full feature unlock when CHATWOOT_UNLOCK_ALL_FEATURES=true.
# Safe to run on every boot (idempotent). Skip quietly if DB is not ready yet.
Rails.application.config.after_initialize do
  next unless ChatwootApp.unlock_all_features?
  next unless defined?(ActiveRecord::Base)

  begin
    ActiveRecord::Base.connection_pool.with_connection do |connection|
      next unless connection.data_source_exists?('installation_configs')
      next unless connection.data_source_exists?('accounts')

      result = Internal::UnlockAllFeaturesService.new.perform
      Rails.logger.info("[UnlockAllFeatures] #{result.inspect}") if result[:unlocked]
    end
  rescue ActiveRecord::NoDatabaseError, ActiveRecord::ConnectionNotEstablished => e
    Rails.logger.warn("[UnlockAllFeatures] skipped: #{e.class}: #{e.message}")
  end
end
