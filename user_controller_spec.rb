require 'spec_helper'
require 'mongo'

describe UserController do
  before do
    mongo_hash = get_environment_value('mongo', nil, 'hosts', nil)
    mongo_uris = get_mongo_uri_array_from_hash(mongo_hash)
    database_name = get_environment_value('mongo', nil, 'database', nil)
    client = Mongo::MongoReplicaSetClient.new(mongo_uris)
    client.connect
    db = client[database_name]

    db.collections.each do |collection|
      unless collection.name.match(/^system\./)
        collection.remove
      end
    end

    collection = db['Users']
    collection.insert({ 'LoginName' => 'jsmith', 'ProfileId' => '2345', 'UserId' => '1234', 'AccountStatus' => 'Active', 'UserStatus' => 'Active', 'ProfileType' => 'Team' })
    collection.insert({ 'LoginName' => 'nocontactuser', 'UserId' => '8989','AccountStatus' => 'Active', 'UserStatus' => 'Active', 'ProfileType' => 'Team' })

    collection = db['UserDailyContacts']
    collection.insert({ 'v' => 1, 'UserId' => '1234', 'ProfileId' => '2345',
                        'Day' => Time.utc(2013,03,30), 'New' => 20, 'Total' => 20 })
    collection.insert({ 'v' => 1, 'UserId' => '1234', 'ProfileId' => '2345',
                        'Day' => Time.utc(2013,03,31), 'New' => 30, 'Total' => 50 })
    collection.insert({ 'v' => 1, 'UserId' => '1234', 'ProfileId' => '2345',
                        'Day' => Time.utc(2013,04,01), 'New' => 10, 'Total' => 60 })
    collection.insert({ 'v' => 1, 'UserId' => '5678', 'ProfileId' => '2345',
                        'Day' => Time.utc(2013,03,30), 'New' => 42, 'Total' => 42 })
    collection.insert({ 'v' => 1, 'UserId' => '9876', 'ProfileId' => '2345',
                        'Day' => Time.utc(2013,03,30), 'New' => 10, 'Total' => 10 })
    collection.insert({ 'v' => 1, 'UserId' => '9876', 'ProfileId' => '2345',
                        'Day' => Time.utc(2013,03,30), 'New' => 20, 'Total' => 30 })
    collection.insert({ 'v' => 1, 'UserId' => '8765', 'ProfileId' => '2345',
                        'Day' => Time.utc(2013,03,30), 'New' => 32, 'Total' => 32 })

    collection = db['UserTouchPoints']
    collection.insert({ 'v' => 1, 'UserId' => '1234', 'ProfileId' => '2345',
              'ActivityId' => '1', 'ContactId' => '1', 'ActivityType' => 'Call',
              'Day' => Time.utc(2013,03,30)})
    collection.insert({ 'v' => 1, 'UserId' => '1234', 'ProfileId' => '2345',
              'ActivityId' => '2', 'ContactId' => '1', 'ActivityType' => 'Appointment',
              'Day' => Time.utc(2013,03,30)})
    collection.insert({ 'v' => 1, 'UserId' => '1234', 'ProfileId' => '2345',
              'ActivityId' => '3', 'ContactId' => '2', 'ActivityType' => 'Call',
              'Day' => Time.now.utc})
    collection.insert({ 'v' => 1, 'UserId' => '1234', 'ProfileId' => '2345',
              'ActivityId' => '4', 'ContactId' => '3', 'ActivityType' => 'Appointment',
              'Day' => Time.now.utc})

    collection = db['UserTransactions']
    collection.insert({ 'v' => 1, 'UserId' => '1234', 'ProfileId' => '2345',
                        'Day' => Time.now.utc, 'Buyer' => true, 'Seller' => true, 'TransactionId' => '21012' })
    collection.insert({ 'v' => 1, 'UserId' => '1234', 'ProfileId' => '2345',
                        'Day' => Time.now.utc - 1.day, 'Buyer' => true, 'TransactionId' => '21333' })
    collection.insert({ 'v' => 1, 'UserId' => '1234', 'ProfileId' => '2345',
                        'Day' => Time.now.utc - 1.year,  'Seller' => true, 'TransactionId' => '21222' })
    collection.insert({ 'v' => 1, 'UserId' => '1234', 'ProfileId' => '2345',
                        'Day' => Time.now.utc - 391.day, 'Buyer' => true, 'TransactionId' => '212111' })
  end

  subject { @controller }

  describe('onlythissuite') do
    it 'onlythistest' do
      puts 'here'
    end
  end

# contacts count
  describe('getting the count of contacts for a user') do
    it "should return a valid user's contact total when passed a valid login" do
      get :contacts_count_for_login, {login: 'jsmith'}

      response.status.should eq(200)

      json = response.body
      data = JSON.parse(json)

      data['UserId'].should eq('1234')
      data['ProfileId'].should eq('2345')
      data['Total'].should eq(60)
    end

    it 'should return failure JSON data when an invalid login is passed' do
      get :contacts_count_for_login, {login: 'doesnotexist'}

      response.status.should eq(404)

      json = response.body
      data = JSON.parse(json)

      data['error'].should eq('Login name does not exist')
    end

    it 'should return that no contacts exist for a user that has none' do
      get :contacts_count_for_login, {login: 'nocontactuser'}

      response.status.should eq(404)

      json = response.body
      data = JSON.parse(json)

      data['error'].should eq('This user has no contacts')
    end
  end

  describe('getting the number of new contacts created for a user') do
    describe('within a date range') do

    end

    describe('for a date range') do
      it 'should return failure JSON data when an invalid login is passed' do
        get :contacts_count_created_in_date_range_for_login, {login: 'doesnotexist', startDate: '2013-03-30', endDate: '2013-03-31'}

        response.status.should eq(404)

        json = response.body
        data = JSON.parse(json)

        data['error'].should eq('Login name does not exist')
      end

      it 'should return valid data when the input values are correct and the user exists' do
        get :contacts_count_created_in_date_range_for_login, {login: 'jsmith', startDate: '2013-03-30', endDate: '2013-03-31'}

        response.status.should eq(200)

        json = response.body
        data = JSON.parse(json)

        data['login'].should eq('jsmith')
        data['start_date'].should eq('2013-03-30')
        data['end_date'].should eq('2013-03-31')
        data['count'].should eq(50)
      end

      it 'should return a zero count when the input values are correct and the user exists but has no contacts' do
        get :contacts_count_created_in_date_range_for_login, {login: 'nocontactuser', startDate: '2013-03-30', endDate: '2013-03-31'}

        response.status.should eq(200)

        json = response.body
        data = JSON.parse(json)

        data['login'].should eq('nocontactuser')
        data['start_date'].should eq('2013-03-30')
        data['end_date'].should eq('2013-03-31')
        data['count'].should eq(0)
      end

      it 'should fail when the start date is not earlier than the end date' do
        get :contacts_count_created_in_date_range_for_login, {login: 'jsmith', startDate: '2013-03-31', endDate: '2013-03-30'}
        response.status.should eq(400)
      end

      describe('testing the date format') do
        describe('for the start date') do
          it 'should return okay when the date is correct' do
            get :contacts_count_created_in_date_range_for_login, {login: 'jsmith', startDate: '2013-03-30', endDate: '2013-03-31'}
            response.status.should eq(200)
          end

          it 'should return an error when the year part is invalid' do
            get :contacts_count_created_in_date_range_for_login, {login: 'jsmith', startDate: '201322-03-30', endDate: '2013-03-31'}
            response.status.should eq(400)
          end

          it 'should return an error when the month part is invalid' do
            get :contacts_count_created_in_date_range_for_login, {login: 'jsmith', startDate: '2013-13-30', endDate: '2013-03-31'}
            response.status.should eq(400)
          end

          it 'should return an error when the day part is invalid' do
            get :contacts_count_created_in_date_range_for_login, {login: 'jsmith', startDate: '2013-03-32', endDate: '2013-03-31'}
            response.status.should eq(400)
          end
        end

        describe('for the end date') do
          it 'should return okay when the date is correct' do
            get :contacts_count_created_in_date_range_for_login, {login: 'jsmith', startDate: '2013-03-30', endDate: '2013-03-31'}
            response.status.should eq(200)
          end

          it 'should return an error when the year part is invalid' do
            get :contacts_count_created_in_date_range_for_login, {login: 'jsmith', startDate: '2013-03-30', endDate: '201322-03-31'}
            response.status.should eq(400)
          end

          it 'should return an error when the month part is invalid' do
            get :contacts_count_created_in_date_range_for_login, {login: 'jsmith', startDate: '2013-03-30', endDate: '2013-13-31'}
            response.status.should eq(400)
          end

          it 'should return an error when the day part is invalid' do
            get :contacts_count_created_in_date_range_for_login, {login: 'jsmith', startDate: '2013-03-30', endDate: '2013-03-32'}
            response.status.should eq(400)
          end
        end
      end
    end

    describe('for a specific month') do
      it 'should return failure JSON data when an invalid login is passed' do
        get :contacts_count_created_for_month_for_login, {login: 'doesnotexist', month: '2013-01'}

        response.status.should eq(404)

        json = response.body
        data = JSON.parse(json)

        data['error'].should eq('Login name does not exist')
      end

      it 'should return valid data when the input values are correct and the user exists' do
        get :contacts_count_created_for_month_for_login, {login: 'jsmith', month: '2013-03'}

        response.status.should eq(200)

        json = response.body
        data = JSON.parse(json)

        data['login'].should eq('jsmith')
        data['start_date'].should eq('2013-03-01')
        data['end_date'].should eq('2013-03-31')
        data['count'].should eq(50)
      end

      it 'should return a zero count when the input values are correct and the user exists but has no contacts' do
        get :contacts_count_created_for_month_for_login, {login: 'nocontactuser', month: '2013-03'}

        response.status.should eq(200)

        json = response.body
        data = JSON.parse(json)

        data['login'].should eq('nocontactuser')
        data['start_date'].should eq('2013-03-01')
        data['end_date'].should eq('2013-03-31')
        data['count'].should eq(0)
      end

      describe('testing the month format') do
        it 'should return okay when the entire month format is valid' do
          get :contacts_count_created_for_month_for_login, {login: 'jsmith', month: '2013-03'}
          response.status.should eq(200)
        end

        it 'should return an error when the year part is invalid' do
          get :contacts_count_created_for_month_for_login, {login: 'jsmith', month: '201322-03'}
          response.status.should eq(400)
        end

        it 'should return an error when the month part is invalid' do
          get :contacts_count_created_for_month_for_login, {login: 'jsmith', month: '2013-13'}
          response.status.should eq(400)
        end
      end
    end
  end
# touchpoints 
  describe('getting the number of touchpoints/contacted for a user') do
    describe('for a date range') do
      it 'should return failure JSON data when an invalid login is passed' do
        get :contacts_contacted_in_date_range_for_login, {login: 'doesnotexist', startDate: '2013-03-30', endDate: '2013-03-31'}
        response.status.should eq(404)
        json = response.body
        data = JSON.parse(json)
        data['error'].should eq('Login name does not exist')
      end

      it 'should return valid data when the input values are correct and the user exists' do
        get :contacts_contacted_in_date_range_for_login, {login: 'jsmith', startDate: '2013-03-01', endDate: '2013-03-31'}
        response.status.should eq(200)
        json = response.body
        data = JSON.parse(json)
        data['login'].should eq('jsmith')
        data['start_date'].should eq('2013-03-01')
        data['end_date'].should eq('2013-03-31')
        data['count'].should eq(1)
      end

      it 'should return a zero count when the input values are correct and the user exists but has no touchpoints' do
        get :contacts_contacted_in_date_range_for_login, {login: 'nocontactuser', startDate: '2013-01-30', endDate: '2013-01-31'}
        response.status.should eq(200)
        json = response.body
        data = JSON.parse(json)
        data['login'].should eq('nocontactuser')
        data['start_date'].should eq('2013-01-30')
        data['end_date'].should eq('2013-01-31')
        data['count'].should eq(0)
      end

      it 'should fail when the start date is not earlier than the end date in the same month' do
        get :contacts_contacted_in_date_range_for_login, {login: 'jsmith', startDate: '2013-03-31', endDate: '2013-03-30'}
        response.status.should eq(400)
      end

      it 'should fail when the start date is not earlier than the end date  in the same month' do
        get :contacts_contacted_in_date_range_for_login, {login: 'jsmith', startDate: '2013-03-11', endDate: '2013-02-20'}
        response.status.should eq(400)
      end
      
      describe('testing the date format') do
        describe('for the start date') do
          it 'should return okay when the date is correct' do
            get :contacts_contacted_in_date_range_for_login, {login: 'jsmith', startDate: '2013-03-30', endDate: '2013-03-31'}
            response.status.should eq(200)
          end

          it 'should return an error when the year part is invalid' do
            get :contacts_contacted_in_date_range_for_login, {login: 'jsmith', startDate: '201322-03-30', endDate: '2013-03-31'}
            response.status.should eq(400)
          end

          it 'should return an error when the month part is invalid' do
            get :contacts_contacted_in_date_range_for_login, {login: 'jsmith', startDate: '2013-13-30', endDate: '2013-03-31'}
            response.status.should eq(400)
          end

          it 'should return an error when the day part is invalid' do
            get :contacts_contacted_in_date_range_for_login, {login: 'jsmith', startDate: '2013-03-32', endDate: '2013-03-31'}
            response.status.should eq(400)
          end
        end

        describe('for the end date') do
          it 'should return okay when the date is correct' do
            get :contacts_contacted_in_date_range_for_login, {login: 'jsmith', startDate: '2013-03-30', endDate: '2013-03-31'}
            response.status.should eq(200)
          end

          it 'should return an error when the year part is invalid' do
            get :contacts_contacted_in_date_range_for_login, {login: 'jsmith', startDate: '2013-03-30', endDate: '201322-03-31'}
            response.status.should eq(400)
          end

          it 'should return an error when the month part is invalid' do
            get :contacts_contacted_in_date_range_for_login, {login: 'jsmith', startDate: '2013-03-30', endDate: '2013-13-31'}
            response.status.should eq(400)
          end

          it 'should return an error when the day part is invalid' do
            get :contacts_contacted_in_date_range_for_login, {login: 'jsmith', startDate: '2013-03-30', endDate: '2013-03-32'}
            response.status.should eq(400)
          end
        end
      end
    end

   describe('for current month') do
      it 'should return failure JSON data when an invalid login is passed' do
        get :contacts_contacted_for_month_for_login, {login: 'doesnotexist'}
        response.status.should eq(404)
        json = response.body
        data = JSON.parse(json)
        data['error'].should eq('Login name does not exist')
      end

      it 'should return valid data when the input values are correct and the user exists' do
        get :contacts_contacted_for_month_for_login, {login: 'jsmith'}
        response.status.should eq(200)
        json = response.body
        data = JSON.parse(json)
        data['login'].should eq('jsmith')
        data['count'].should eq(2)
      end
      it 'should return a zero count when the input values are correct and the user exists but has no touchpoints' do
        get :contacts_contacted_for_month_for_login, {login: 'nocontactuser'}
        response.status.should eq(200)
        json = response.body
        data = JSON.parse(json)
        data['login'].should eq('nocontactuser')
        data['count'].should eq(0)
      end
      describe('testing the optional activity type') do
        it 'should return okay and filtered by call type' do
          get :contacts_contacted_for_month_for_login, {login: 'jsmith', activityType: 'Call'}
          response.status.should eq(200)
          json = response.body
          data = JSON.parse(json)
          data['count'].should eq(1)
        end
        it 'should return okay and filtered by appointment type' do
          get :contacts_contacted_for_month_for_login, {login: 'jsmith', activityType: 'Appointment'}
          response.status.should eq(200)
          json = response.body
          data = JSON.parse(json)
          data['count'].should eq(1)
        end
      end
    end
   
   describe('for year to date') do
      it 'should return failure JSON data when an invalid login is passed' do
        get :contacts_contacted_year_to_date_for_login, {login: 'doesnotexist'}
        response.status.should eq(404)
        json = response.body
        data = JSON.parse(json)
        data['error'].should eq('Login name does not exist')
      end

      it 'should return valid data when the input values are correct and the user exists' do
        get :contacts_contacted_year_to_date_for_login, {login: 'jsmith'}
        response.status.should eq(200)
        json = response.body
        data = JSON.parse(json)
        data['login'].should eq('jsmith')
        data['count'].should eq(3)
      end
      it 'should return a zero count when the input values are correct and the user exists but has no touchpoints' do
        get :contacts_contacted_year_to_date_for_login, {login: 'nocontactuser'}
        response.status.should eq(200)
        json = response.body
        data = JSON.parse(json)
        data['login'].should eq('nocontactuser')
        data['count'].should eq(0)
      end
      describe('testing the optional activity type') do
        it 'should return okay and filtered by call type' do
          get :contacts_contacted_year_to_date_for_login, {login: 'jsmith', activityType: 'Call'}
          response.status.should eq(200)
          json = response.body
          data = JSON.parse(json)
          data['count'].should eq(2)
        end
        it 'should return okay and filtered by appointment type' do
          get :contacts_contacted_year_to_date_for_login, {login: 'jsmith', activityType: 'Todo'}
          response.status.should eq(200)
          json = response.body
          data = JSON.parse(json)
          data['count'].should eq(0)
        end
      end
    end
  end #eof touchpoints
#transactions
  describe('getting the number of closed transactions for a user') do
 
   describe('for last year') do
      it 'should return failure JSON data when an invalid login is passed' do
        get :transactions_count_for_last_year_for_login, {login: 'doesnotexist'}
        response.status.should eq(404)
        json = response.body
        data = JSON.parse(json)
        data['error'].should eq('Login name does not exist')
      end

      it 'should return valid data when the input values are correct and the user exists' do
        get :transactions_count_for_last_year_for_login, {login: 'jsmith'}
        response.status.should eq(200)
        json = response.body
        data = JSON.parse(json)
        data['login'].should eq('jsmith')
        data['count_buyer'].should eq(1)
        data['count_seller'].should eq(1)
      end
      it 'should return a zero count when the user exists but has no transactions' do
        get :transactions_count_for_last_year_for_login, {login: 'nocontactuser'}
        response.status.should eq(200)
        json = response.body
        data = JSON.parse(json)
        data['login'].should eq('nocontactuser')
        data['count_buyer'].should eq(0)
        data['count_seller'].should eq(0)
      end
    end
   
   describe('for year to date') do
      it 'should return failure JSON data when an invalid login is passed' do
        get :transactions_count_year_to_date_for_login, {login: 'doesnotexist'}
        response.status.should eq(404)
        json = response.body
        data = JSON.parse(json)
        data['error'].should eq('Login name does not exist')
      end

      it 'should return valid data when the input values are correct and the user exists' do
        get :transactions_count_year_to_date_for_login, {login: 'jsmith'}
        response.status.should eq(200)
        json = response.body
        data = JSON.parse(json)
        data['login'].should eq('jsmith')
        data['count_buyer'].should eq(2)
        data['count_seller'].should eq(1)
      end
      it 'should return a zero count when the user exists but has no transactions' do
        get :transactions_count_year_to_date_for_login, {login: 'nocontactuser'}
        response.status.should eq(200)
        json = response.body
        data = JSON.parse(json)
        data['count_buyer'].should eq(0)
        data['count_seller'].should eq(0)
      end

    end
  end 
  #eof transactions specs  
end #eof
