# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy.
# See the Securing Rails Applications Guide for more information:
# https://guides.rubyonrails.org/security.html#content-security-policy-header

Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self
    policy.font_src    :self, :data, "https://fonts.gstatic.com"
    policy.img_src     :self, :data, :blob
    policy.object_src  :none
    policy.script_src  :self
    policy.style_src   :self, :unsafe_inline, "https://fonts.googleapis.com"
    policy.frame_src   :self, "https://www.youtube.com"
    policy.connect_src :self

    # Allow Action Cable WebSocket connections
    if Rails.env.development?
      policy.connect_src :self, "ws://localhost:*", "wss://localhost:*"
    end

    # Specify URI for violation reports
    # policy.report_uri "/csp-violation-report-endpoint"
  end

  # Generate session nonces for permitted importmap, inline scripts, and inline styles.
  config.content_security_policy_nonce_generator = ->(request) { request.session.id.to_s }
  config.content_security_policy_nonce_directives = %w[script-src style-src]

  # Report violations without enforcing the policy (enable for testing first).
  config.content_security_policy_report_only = true
end
