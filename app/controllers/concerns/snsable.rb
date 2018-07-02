require 'aws-sdk-sns' 


module Snsable
  extend ActiveSupport::Concern
  
  # SNS SANDBOX ARN    arn:aws:sns:us-east-1:349442810440:app/APNS_SANDBOX/Challenge_APNS_Development
  # SNS PRODCTION ARN  arn:aws:sns:us-east-1:349442810440:app/APNS/Challenge_APNS_Production
  APPLICATION_ARN = "arn:aws:sns:us-east-1:349442810440:app/APNS_SANDBOX/Challenge_APNS_Development"
  
  included do
    @@sns = Aws::SNS::Client.new(region: 'us-east-1',
      access_key_id: Rails.application.credentials.dig(:aws, :sns, :access_key_id),
      secret_access_key: Rails.application.credentials.dig(:aws, :sns, :secret_access_key))
  end
  
  # Makes sure the user's current APNS Device Token (from their iOS device) is associated with a valid SNS endpoint ARN (used to push)
  def register_device_token
      
    # 1) Make sure user has an endpoin ARN
    if self.sns_platform_endpoint_arn == nil
      create_platform_endpoint
    end
    
    # 2) Make sure that endpoint ARN is valid and up to date
    endpoint_attributes = nil
    begin
      endpoint_attributes = @@sns.get_endpoint_attributes({ endpoint_arn: self.sns_platform_endpoint_arn })
    rescue Aws::SNS::Errors::ServiceError
      # Could have a stale endpoint ARN, try to re-create
      create_platform_endpoint
    end
      
    begin
      if endpoint_attributes and 
        (endpoint_attributes.attributes["Token"] != self.apns_device_token or endpoint_attributes.attributes["Enabled"] != "true")
        resp = @@sns.set_endpoint_attributes({
          endpoint_arn: self.sns_platform_endpoint_arn,
          attributes: {
            "Token" => self.apns_device_token,
            "CustomUserData" => "user_id:#{self.id}",
          }
        })
        #expecting an empty response
      end
      
    rescue Aws::SNS::Errors::ServiceError
      # rescues all service API errors
    end
  end
  
  def push(message)
    note = { aps: 
              { alert: message,
                #badge: 1,
                sound: "default" 
              }
            }
    message = { APNS_SANDBOX: note.to_json, APNS: note.to_json }
    @@sns.publish({
      target_arn: self.sns_platform_endpoint_arn,
      message: message.to_json,
      message_structure: :json
    })
  end
  
  private 
  
    def create_platform_endpoint
      begin
        resp = @@sns.create_platform_endpoint({
          platform_application_arn: APPLICATION_ARN,
          token: self.apns_device_token,
          custom_user_data: "user_id:#{self.id}",
        })
    
        self.update(sns_platform_endpoint_arn: resp.endpoint_arn)
      rescue Aws::SNS::Errors::ServiceError
        #?
      end
    end
  
end
