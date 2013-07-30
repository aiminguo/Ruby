require 'mongo'

#   match '/v1/user/contacts/count/createdInDateRange/:login/:startDate/:endDate'=>'user#contacts_count_created_in_date_range_for_login'
#   match '/v1/user/contacts/count/createdForMonth/:login/:month' => 'user#contacts_count_created_for_month_for_login'
#   match '/v1/user/contacts/count/:login' => 'user#contacts_count_for_login'

include ApplicationHelper

class UserController < ApplicationController
  ERROR_LOGIN_NOT_EXIST = '{"error": "Login name does not exist"}'
  STATUS_ERROR = 400

  def initialize
    mongo_hash = get_environment_value('mongo', nil, 'hosts', nil)
    mongo_uris = get_mongo_uri_array_from_hash(mongo_hash)
    database_name = get_environment_value('mongo', nil, 'database', nil)
    client = Mongo::MongoReplicaSetClient.new(mongo_uris)
    client.connect
    @db = client[database_name]
  end

  def validate_login_name(login)
    collection = @db['Users']
    user = collection.find_one( { 'LoginName' => login, 'AccountStatus' => 'Active', 'UserStatus' => 'Active'})
    if user.nil?
      render json: ERROR_LOGIN_NOT_EXIST, status: :not_found, callback: params[:callback] #?jsonp=parseResponse
      return nil, nil, nil
    end
    return user['UserId'], user['ProfileId'], user['ProfileType']    
  end
  
  def invalid_start_end_date?(start_date, end_date)
    if !validate_date_format(start_date)
      render json: '{"error": "The start date format or date is invalid"}', status: STATUS_ERROR, callback: params[:callback]
      return true
    end
    if !validate_date_format(end_date)
      render json: '{"error": "The end date format or date is invalid"}', status: STATUS_ERROR, callback: params[:callback]
      return true
    end
  
    start_date_parts = start_date.split('-')
    start_date_utc = Time.utc(start_date_parts[0], start_date_parts[1], start_date_parts[2])
    end_date_parts = end_date.split('-')
    end_date_utc = Time.utc(end_date_parts[0], end_date_parts[1], end_date_parts[2])
    if end_date_utc < start_date_utc
      render json: '{"error": "The end date cannot be earlier than the start date"}', status: STATUS_ERROR, callback: params[:callback]
      return true
    end    
    false
  end
  
  def invalid_month?(month)
    if !validate_month_format(month)
      render json: '{"error": "The month format is invalid"}', status: STATUS_ERROR, callback: params[:callback]
      return true
    end    
    false
  end
  
  def validate_month_format(month)
    month_parts = month.split('-')
    return false if month_parts.count != 2
    return false if month_parts[0].length < 4 || month_parts[0].length > 4
    return false if month_parts[1].length < 2 || month_parts[1].length > 2
    return false if !(month_parts[0].match(/[0-9]{4}/))
    return false if !(month_parts[1].match(/[0-9]{2}/))
    return false if !(month_parts[1].match(/0[1-9]|1[0-2]/))
    begin
      Time.utc(month_parts[0], month_parts[1])
    rescue
      return false
    end
    true
  end

  def validate_date_format(date)
    date_parts = date.split('-')
    return false if date_parts.count != 3
    return false if date_parts[0].length < 4 || date_parts[0].length > 4
    return false if date_parts[1].length < 2 || date_parts[1].length > 2
    return false if date_parts[2].length < 2 || date_parts[1].length > 2
    return false if !(date_parts[0].match(/[0-9]{4}/))
    return false if !(date_parts[1].match(/[0-9]{2}/))
    return false if !(date_parts[1].match(/0[1-9]|1[0-2]/))
    return false if !(date_parts[2].match(/[0-9]{2}/))
    return false if !(date_parts[2].match(/0[1-9]|1[0-9]|2[0-9]|3[0-1]/))
    begin
      Time.utc(date_parts[0], date_parts[1], date_parts[2])
    rescue
      return false
    end
    true
  end

  def mongo_data_for_login
    login = params[:login]
    user_id, profile_id, profile_type = validate_login_name(login)
    return if user_id.nil?   
    doc_list = {'c' => 'UserDailyContacts', 'a' => 'UserTouchPoints', 't' => 'UserTransactions'}
    doc_name = doc_list[params[:category]]
    collection = @db[doc_name||doc_list['c']]
     
    @user = collection.find( { 'ProfileId' => profile_id} ).sort( { 'Day' => -1 } ).limit(10)
    
    if @user.nil?
      render json: '{ "error": "This user has no data" }', status: :not_found, callback: params[:callback]
      return
    end
    render json: @user, callback: params[:callback]
  end
  
  def contacts_count_for_login 
    login = params[:login]
    user_id, profile_id, profile_type = validate_login_name(login)
    return if user_id.nil?

    collection = @db['UserDailyContacts']
    user_id = profile_type == 'Agent' ? nil : user_id
    @user = collection.find( { 'ProfileId' => profile_id, 'UserId' => user_id } ).sort( { 'Day' => -1 } ).limit(1).collect.first

    if @user.nil?
      render json: '{ "error": "This user has no contacts" }', status: :not_found, callback: params[:callback]
      return
    end

    render json: @user, callback: params[:callback]
  end

  def contacts_count_created_in_date_range_for_login
    login = params[:login]
    start_date = params[:startDate]
    end_date = params[:endDate]
    return if invalid_start_end_date?(start_date, end_date)

    contacts_count_created_in_date_range_for_login_internal(login, start_date, end_date)
  end

  def contacts_count_created_for_month_for_login
    login = params[:login]
    month = params[:month]
    return if invalid_month?(month)

    month_parts = month.split('-')
    month_utc = Time.utc(month_parts[0], month_parts[1])
    nextmonth = month_utc.next_month - 1.day
    contacts_count_created_in_date_range_for_login_internal login, month_utc.strftime('%Y-%m-%d'), nextmonth.strftime('%Y-%m-%d')
  end

  def contacts_count_created_in_date_range_for_login_internal(login, start_date, end_date)
    user_id, profile_id, profile_type = validate_login_name(login)
    return if user_id.nil?
    if profile_type == 'Agent'
      filter_id_name = 'ProfileId'
      filter_id_value = profile_id
    else
      filter_id_name = 'UserId'
      filter_id_value = user_id     
    end
    
    start_date_parts = start_date.split('-')
    start_date_utc = Time.utc(start_date_parts[0], start_date_parts[1], start_date_parts[2])
    end_date_parts = end_date.split('-')
    end_date_utc = Time.utc(end_date_parts[0], end_date_parts[1], end_date_parts[2]) + 1.day

    collection = @db['UserDailyContacts']
    result = collection.aggregate([
                                      {
                                          '$match' =>
                                              {
                                                  "#{filter_id_name}" => "#{filter_id_value}",
                                                  'Day' =>
                                                      {
                                                          '$gte' => start_date_utc ,
                                                          '$lt' => end_date_utc
                                                      }
                                              }
                                      },
                                      {
                                          '$group' =>
                                              {
                                                  '_id' => "$#{filter_id_name}",
                                                  'count' => { '$sum' => '$New' }
                                              }
                                      }
                                  ])
    #
    #Format the JSON then return it.
    if result.empty?
      count = 0
    else
      count = result[0]['count']
    end

    json = "{ \"login\": \"#{login}\", \"start_date\": \"#{start_date}\", \"end_date\": \"#{end_date}\", \"count\":  #{count}}"
    render json: json, status: :ok, callback: params[:callback]
  end
  
  def contacts_contacted_in_date_range_for_login
    login = params[:login]
  	start_date = params[:startDate]
  	end_date = params[:endDate]
  	activity_type = params[:activityType] 
    return if invalid_start_end_date?(start_date, end_date)
  	contacts_contacted_in_date_range_for_login_internal(login, start_date, end_date, activity_type)
  end
   
  def contacts_contacted_for_month_for_login
    login = params[:login]
    activity_type = params[:activityType] 

    month = Time.now.utc.strftime('%Y-%m')
    month_parts = month.split('-')
    month_utc = Time.utc(month_parts[0], month_parts[1])
    nextmonth = month_utc.next_month - 1.day
    contacts_contacted_in_date_range_for_login_internal(login, month_utc.strftime('%Y-%m-%d'), nextmonth.strftime('%Y-%m-%d'), activity_type)
  end

  def contacts_contacted_year_to_date_for_login
    login = params[:login]
    activity_type = params[:activityType] 

    end_date = Time.now.utc.strftime('%Y-%m-%d')
    start_date = end_date.split('-').first + '-01-01'
    contacts_contacted_in_date_range_for_login_internal(login, start_date, end_date, activity_type)
  end
  
  def contacts_contacted_in_date_range_for_login_internal(login, start_date, end_date, activity_type)

    user_id, profile_id, profile_type = validate_login_name(login)
    return if user_id.nil?

    activity_type = 'Call,Appointment' if activity_type.nil?
    activity_type = activity_type.split(',')

    start_date_parts = start_date.split('-')
    start_date_utc = Time.utc(start_date_parts[0], start_date_parts[1], start_date_parts[2])
    end_date_parts = end_date.split('-')
    end_date_utc = Time.utc(end_date_parts[0], end_date_parts[1], end_date_parts[2]) + 1.day

    collection = @db['UserTouchPoints']
    result = collection.aggregate([
                                  {
                                      '$match' =>
                                          {
                                              'UserId' => "#{user_id}",
                                              'ActivityType' =>
                                                  {
                                                      '$in' => activity_type
                                                  },
                                              'Day' =>
                                                  {
                                                      '$gte' => start_date_utc ,
                                                      '$lt' => end_date_utc
                                                  }
                                          }
                                  },
                                  {
                                      '$group' =>
                                          {
                                              '_id' => '$ContactId',
                                              'count' => { '$sum' => 1 }
                                          }
                                  },
                                  {
                                      '$project' =>
                                          {
                                              '_id' => 0,
                                              'ContactId' => '$_id',
                                              't' => {'$concat' => ['t']}
                                          }
                                  },
                                  {
                                      '$group' =>
                                          {
                                              '_id' => '$t',
                                              'count' => {'$sum' => 1}
                                          }
                                  },
                                  {
                                      '$project' =>
                                          {
                                              '_id' => 0,
                                              'count' => 1
                                          }
                                  }
                              ])
                              
    #Format the JSON then return it.
    if result.empty?
      count = 0
    else
      count = result[0]['count']
    end

    json = "{ \"login\": \"#{login}\", \"start_date\": \"#{start_date}\", \"end_date\": \"#{end_date}\", \"count\":  #{count}}"

    render json: json, status: :ok, callback: params[:callback]
  end  
  
  def transactions_count_for_last_year_for_login
    login = params[:login]
    first_day_in_current_year = Time.utc(Time.now.utc.strftime('%Y-%m-%d').split('-').first,'01', '01')
    end_date = (first_day_in_current_year - 1.day).strftime('%Y-%m-%d')
    start_date = (first_day_in_current_year - 1.year).strftime('%Y-%m-%d')
    transactions_in_date_range_for_login_internal(login, start_date, end_date)      
  end
  
  def transactions_count_year_to_date_for_login
    login = params[:login]
    end_date = Time.now.utc.strftime('%Y-%m-%d')
    start_date = end_date.split('-').first + '-01-01'
    transactions_in_date_range_for_login_internal(login, start_date, end_date)    
  end
  
  def transactions_pipeline(user_id, profile_id, profile_type, role_type, start_date_utc, end_date_utc)
    if profile_type == 'Agent'
      filter_id_name = 'ProfileId'
      filter_id_value = profile_id
    else
      filter_id_name = 'UserId'
      filter_id_value = user_id     
    end    
    [{
            "$match" =>
                {
                    "#{filter_id_name}" => "#{filter_id_value}",
                    "#{role_type}" => true,
                    "Day" =>
                        {
                            "$gte" => start_date_utc ,
                            "$lt" => end_date_utc,
                        }
                }
      }, {
            "$group" =>
                {
                    "_id" => "$#{filter_id_name}",
                    "count" => { "$sum" => 1 }
                }
     }]
  end 
  
  def transactions_in_date_range_for_login_internal(login, start_date, end_date)    
    user_id, profile_id, profile_type = validate_login_name(login)
    return if user_id.nil?
    if profile_type == 'Agent'
      filter_id_name = 'ProfileId'
      filter_id_value = profile_id
    else
      filter_id_name = 'UserId'
      filter_id_value = user_id     
    end

    start_date_parts = start_date.split('-')
    start_date_utc = Time.utc(start_date_parts[0], start_date_parts[1], start_date_parts[2])
    end_date_parts = end_date.split('-')
    end_date_utc = Time.utc(end_date_parts[0], end_date_parts[1], end_date_parts[2]) + 1.day

    collection = @db['UserTransactions']
    result = collection.aggregate(transactions_pipeline(user_id, profile_id, profile_type, 'Buyer', start_date_utc, end_date_utc))
    count_buyer = result.empty? ? 0 : result[0]['count']

    result = collection.aggregate(transactions_pipeline(user_id, profile_id, profile_type, 'Seller', start_date_utc, end_date_utc))
    count_seller = result.empty? ? 0 : result[0]['count'] 
  
    #Format the JSON then return it.
    json = "{ \"login\": \"#{login}\", \"start_date\": \"#{start_date}\", \"end_date\": \"#{end_date}\", 
      \"count_buyer\":  #{count_buyer}, \"count_seller\":  #{count_seller}}"
    render json: json, status: :ok, callback: params[:callback]
  end  
end
