require 'aws-sdk-sns' 


module Snsable
  extend ActiveSupport::Concern  
  
  included do
    @@sns = Aws::SNS::Client.new(region: 'us-east-1',
      access_key_id: Rails.application.credentials.dig(:aws, :sns, :access_key_id),
      secret_access_key: Rails.application.credentials.dig(:aws, :sns, :secret_access_key))
  end
  
  # Makes sure the user's current APNS Device Token (from their iOS device) is associated with a valid SNS endpoint ARN (used to push)
  def register_device_token_for_sandbox(sandbox)
    return unless self.apns_device_token_for_sandbox(sandbox)
      
    # 1) Make sure user has an endpoint ARN
    if self.sns_platform_endpoint_arn_for_sandbox(sandbox) == nil
      create_platform_endpoint_for_sandbox(sandbox)
    end
    
    # 2) Make sure that endpoint ARN is valid and up to date
    endpoint_attributes = nil
    begin
      endpoint_attributes = @@sns.get_endpoint_attributes({ endpoint_arn: self.sns_platform_endpoint_arn_for_sandbox(sandbox) })
    rescue Aws::SNS::Errors::ServiceError
      # Could have a stale endpoint ARN, try to re-create
      create_platform_endpoint_for_sandbox(sandbox)
    end
      
    begin
      if endpoint_attributes and 
        (endpoint_attributes.attributes["Token"] != self.apns_device_token_for_sandbox(sandbox) or 
         endpoint_attributes.attributes["Enabled"] != "true")
        resp = @@sns.set_endpoint_attributes({
          endpoint_arn: self.sns_platform_endpoint_arn_for_sandbox(sandbox),
          attributes: {
            "Token" => self.apns_device_token_for_sandbox(sandbox),
            "CustomUserData" => self.sns_custom_user_data,
          }
        })
        #expecting an empty response
      end
      
    rescue Aws::SNS::Errors::ServiceError
      # rescues all service API errors
    end
  end
  
  def pushRemoteNotification(message, custom_data, sandbox = !Rails.env.production?)
    return unless self.sns_platform_endpoint_arn_for_sandbox(sandbox)
    
    note = { aps: 
              { alert: message,
                #badge: 1,
                sound: "default" 
              }
            }
    note.merge!(custom_data) if custom_data.is_a?(Hash)
    msg = { APNS_SANDBOX: note.to_json, APNS: note.to_json }
    begin
      @@sns.publish({
        target_arn: self.sns_platform_endpoint_arn_for_sandbox(sandbox),
        message: msg.to_json,
        message_structure: :json
      })
    rescue Aws::SNS::Errors::ServiceError
      # rescues all service API errors
    end
  end
  
  def apns_device_token_for_sandbox(sandbox)
    return (sandbox ? self.apns_sandbox_device_token : self.apns_device_token)
  end
  
  def sns_platform_endpoint_arn_for_sandbox(sandbox)
    return (sandbox ? self.sns_sandbox_platform_endpoint_arn : self.sns_platform_endpoint_arn)
  end
    
  def application_arn_for_sandbox(sandbox)
    return (sandbox ? 
      "arn:aws:sns:us-east-1:349442810440:app/APNS_SANDBOX/Challenge_APNS_Development" :
      "arn:aws:sns:us-east-1:349442810440:app/APNS/Challenge_APNS_Production" )
  end

  def create_platform_endpoint_for_sandbox(sandbox)
    begin
      resp = @@sns.create_platform_endpoint({
        platform_application_arn: application_arn_for_sandbox(sandbox),
        token: self.apns_device_token_for_sandbox(sandbox),
        custom_user_data: self.sns_custom_user_data,
      })
  
      sandbox ? 
        self.update(sns_sandbox_platform_endpoint_arn: resp.endpoint_arn) :
        self.update(sns_platform_endpoint_arn: resp.endpoint_arn)
    rescue Aws::SNS::Errors::ServiceError
      #?
    end
  end
  
  def sns_custom_user_data
    return "screenname:#{self.screenname};user_id:#{self.id}"
  end
  
end
