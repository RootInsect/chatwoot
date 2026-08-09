module Llm::Models
  CONFIG = YAML.load_file(Rails.root.join('config/llm.yml')).freeze

  class << self
    def providers = CONFIG.fetch('providers')
    def models = CONFIG.fetch('models')
    def features = CONFIG.fetch('features')
    def feature_keys = features.keys

    def feature?(feature)
      features.key?(feature.to_s)
    end

    def default_model_for(feature)
      features.dig(feature.to_s, 'default')
    end

    def models_for(feature)
      features.dig(feature.to_s, 'models') || []
    end

    def valid_model_for?(feature, model_name)
      models_for(feature).include?(model_name.to_s)
    end

    def model_config(model_name)
      models[model_name.to_s]
    end

    def provider_for(model_name)
      model_config(model_name)&.dig('provider') || (remote_model_ids.include?(model_name.to_s) ? 'openai' : nil)
    end

    def feature_config(feature_key)
      feature = features[feature_key.to_s]
      return nil unless feature

      {
        models: static_feature_models(feature_key),
        default: feature['default']
      }
    end

    def remote_models
      Integrations::Openai::ModelsFetcher.fetch
    end

    def selectable_models_for(feature)
      remote = remote_models
      return remote if remote.present?

      feature_config(feature)&.dig(:models) || []
    end

    def valid_selectable_model?(feature, model_name)
      remote = remote_models
      return remote_model_ids(remote).include?(model_name.to_s) if remote.present?

      valid_model_for?(feature, model_name)
    end

    def feature_config_for_ui(feature_key)
      config = feature_config(feature_key)
      return nil unless config

      config.merge(models: selectable_models_for(feature_key))
    end

    def models_for_ui
      remote = remote_models
      return models if remote.blank?

      models.merge(
        remote.each_with_object({}) do |model, result|
          result[model[:id]] = {
            'provider' => model[:provider],
            'display_name' => model[:display_name],
            'credit_multiplier' => model[:credit_multiplier]
          }
        end
      )
    end

    def global_model_options
      remote = remote_models
      return remote.map { |model| [model[:display_name] || model[:id], model[:id]] } if remote.present?

      models.map { |id, config| [config['display_name'] || id, id] }
    end

    def known_runtime_model?(model_name)
      model_config(model_name).present?
    end

    private

    def static_feature_models(feature_key)
      models_for(feature_key).filter_map do |model_name|
        model = model_config(model_name)
        next unless model

        {
          id: model_name,
          display_name: model['display_name'],
          provider: model['provider'],
          coming_soon: model['coming_soon'],
          credit_multiplier: model['credit_multiplier']
        }
      end
    end

    def remote_model_ids(remote = remote_models)
      Array(remote).map { |model| model[:id].to_s }
    end
  end
end
