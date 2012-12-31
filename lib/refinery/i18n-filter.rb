module RoutingFilter
  class RefineryLocales < Filter

    def around_recognize(path, env, &block)
      if ::Refinery::I18n.enabled?
        if path =~ %r{^/(#{::Refinery::I18n.locales.keys.join('|')})(/|$)}
          path.sub! %r(^/(([a-zA-Z\-_])*)(?=/|$)) do
            ::I18n.locale = $1
            ''
          end
          path.sub!(%r{^$}) { '/' }
        elsif (loc = extract_locale_from_subdomain(env)).present?
          ::I18n.locale = loc
        else
          ::I18n.locale = ::Refinery::I18n.default_frontend_locale
        end
      end

      yield.tap do |params|
        params[:locale] = ::I18n.locale if ::Refinery::I18n.enabled?
      end
    end

    def extract_locale_from_subdomain(env)
      parsed_locale = ActionDispatch::Http::URL.extract_subdomains(env['HTTP_HOST']).first || ''
      Refinery::I18n.frontend_locales.include?(parsed_locale.to_sym) ? parsed_locale : nil
    end
    

    def around_generate(params, &block)
      locale = params.delete(:locale) || ::I18n.locale

      yield.tap do |result|
        result = result.is_a?(Array) ? result.first : result
        if ::Refinery::I18n.url_filter_enabled? and
           locale != ::Refinery::I18n.default_frontend_locale and
           result !~ %r{^/(#{Refinery::Core.backend_route}|wymiframe)}
          result.sub!(%r(^(http.?://[^/]*)?(.*))) { "#{$1}/#{locale}#{$2}" }
        end
      end
    end

  end
end
