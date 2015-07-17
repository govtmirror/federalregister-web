CarrierWave.configure do |config|
  config.fog_credentials = {
    :aws_access_key_id      => SECRETS['aws']['access_key_id'],
    :aws_secret_access_key  => SECRETS['aws']['secret_access_key'],
    :persistent             => false,
    :provider               => 'AWS',       # required
  }
  config.fog_public    = false

  if Rails.env.production?
    config.fog_directory = "my-fr-files.federalregister.gov"
  else
    config.fog_directory = "my-fr-files.fr2.criticaljuncture.org"
  end
end
