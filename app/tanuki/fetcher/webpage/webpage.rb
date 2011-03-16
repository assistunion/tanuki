class Tanuki::Fetcher::Webpage < Sequel::Model
    many_to_one :controller_class
end