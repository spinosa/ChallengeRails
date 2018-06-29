class WellKnownController < ApplicationController
  
  def apple_app_site_association
    render json: {
                    "applinks": {
                      "apps": [],
                      "details": [
                        {
                          "appID": "8C9UTG7ML3.com.cromulentconsulting.challenge",
                          "paths": ["*"]
                        }
                      ]
                    },
                    "webcredentials": {
                      "apps": [ "8C9UTG7ML3.com.cromulentconsulting.challenge" ]
                    }
                  }
  end
  
end
