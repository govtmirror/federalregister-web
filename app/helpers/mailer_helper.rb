module MailerHelper
  def add_css_file_to_mailer(mailer_path)
    content_for :mailer_template_css, Rails.application.assets.find_asset("mailers/#{mailer_path}")
  end

  def mailer_asset_url(asset)
    base_url =  ActionMailer::Base.default_url_options[:protocol] + 
                  ActionMailer::Base.default_url_options[:host]

    asset_url = base_url + asset_path(asset)
    asset_url = asset_url.gsub('/my/my','/my')
  end

end
