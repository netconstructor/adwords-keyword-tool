class TargetingIdeaService
  attr_accessor :limit
  
  ## Exception Handling
  class NoCredentialsError < StandardError
  end

  def initialize(attributes = nil)
   if attributes
      attributes.each do |key,value|
        send(key.to_s + '=', value)
      end
    end
    @results_limit = limit
    @client = Savon::Client.new "https://adwords.google.com/api/adwords/o/v201008/TargetingIdeaService"
    @credential = Credential.first
    raise NoCredentialsError unless @credential.email.include?('@')
    raise NoCredentialsError unless @credential.password?
    raise NoCredentialsError unless @credential.developer_token?
    raise NoCredentialsError unless @credential.auth_token.blank?
    yield self if block_given?
  end
  
  def suggestions(keyword)
    # use the SOAP protocol to query the AdWords API
    response = @client.get! do |soap|
      soap.xml = xml_string(keyword)
    end
    # make a collection of items from the response
    entries = response.to_hash[:get_response][:rval][:entries]
    # start with an empty array for suggestions
    suggestions = []
    unless entries
      raise "No data returned for this query phrase."
    end
    # parse the response and add a Word object to the array for each item
    entries.each do |item|
      suggestions << parse_response(item)
    end
    # sort the suggestions (by GLOBAL_MONTHLY_SEARCHES)
    suggestions.sort!
  end
  
  private

  # XML request, just the way the AdWords API SOAP protocol wants it!
  def xml_string(keyword)
    xml_string = <<-EOS
    <?xml version="1.0" encoding="UTF-8"?>
    <soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:ns1="https://adwords.google.com/api/adwords/o/v201008" xmlns:ns2="https://adwords.google.com/api/adwords/cm/v201008" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
      <soapenv:Header>
        <ns1:RequestHeader>
          <ns2:authToken>#{@credential.auth_token}</ns2:authToken>
          <ns2:developerToken>#{@credential.developer_token}</ns2:developerToken>
          <ns2:userAgent>#{@credential.user_agent}</ns2:userAgent>
        </ns1:RequestHeader>
      </soapenv:Header>
      <soapenv:Body>
        <ns1:get>
        <ns1:selector>
           <ns1:searchParameters xsi:type="ns1:RelatedToKeywordSearchParameter">
              <ns1:keywords>
                 <ns2:text>#{keyword.phrase}</ns2:text>
                 <ns2:matchType>EXACT</ns2:matchType>
              </ns1:keywords>
           </ns1:searchParameters>
           <ns1:searchParameters xsi:type="ns1:IdeaTextMatchesSearchParameter">
              <ns1:included>#{keyword.phrase}</ns1:included>
           </ns1:searchParameters>
           <ns1:searchParameters xsi:type="ns1:KeywordMatchTypeSearchParameter">
              <ns1:keywordMatchTypes>BROAD</ns1:keywordMatchTypes>
           </ns1:searchParameters>
           <ns1:searchParameters xsi:type="ns1:LanguageTargetSearchParameter">
              <ns1:languageTargets xsi:type="ns2:LanguageTarget">
                <ns2:languageCode>en</ns2:languageCode>
              </ns1:languageTargets>
           </ns1:searchParameters>
           <ns1:ideaType>KEYWORD</ns1:ideaType>
           <ns1:requestType>IDEAS</ns1:requestType>
           <ns1:requestedAttributeTypes>KEYWORD</ns1:requestedAttributeTypes>
           <ns1:requestedAttributeTypes>GLOBAL_MONTHLY_SEARCHES</ns1:requestedAttributeTypes>
           <ns1:paging>
              <ns2:startIndex>0</ns2:startIndex>
              <ns2:numberResults>#{@results_limit}</ns2:numberResults>
           </ns1:paging>
        </ns1:selector>
        </ns1:get>
      </soapenv:Body>
    </soapenv:Envelope>
    EOS
    # delete leading whitespace (spaces, tabs) from each line (and delete newlines, too)
    xml_string.gsub(/^[ \t]+/,'').gsub(/\n/,'')
  end
  
  # The data (and syntax) of the response depends on the parameters sent in the XML request.
  # Parse each item in the response and return a Word object.
  def parse_response(item)
    begin
      phrase = ""
      searches = 0
      if item.kind_of?(Hash)
        item_sub = item[:data]
      elsif item.kind_of?(Array)
        item_sub = item[1]
      else
        Rails.logger.info "Expecting Array or Hash, got #{item.class.name}"
      end
      item_sub.each do |item_subsub|
        case item_subsub[:key]
          when 'KEYWORD'
            phrase = item_subsub[:value][:value][:text]
          when 'GLOBAL_MONTHLY_SEARCHES'
            searches = item_subsub[:value][:value].to_i
          else
            raise TypeError, "Unable to parse the response from the AdWords API query"
        end
      end
    rescue TypeError
      raise TypeError, "A problem with parsing the response from the AdWords API query"
    end
    Rails.logger.info "#{phrase} (#{searches} searches)\n\n"
    word = Word.new(:phrase => phrase, :searches => searches)
  end
  
end
