Google Analytics service can be tested in ruby console:

For Google analytics garb gem is used and its added in gemspec dependencies 

Install the gems with bundle install

Start a console: rake console

Call this Service:

Service::GoogleAnalytics.call(data: {client_id: "gatrepscore@gmail.com", client_secret: "Iontech123", web_id: "UA-53947774-1"})

Sample Output :

{:user=>  {:totalVisit=>6,   :uniqueVisit=>5,   :bounceRate=>40.0,   :visitLength=>7,   :conversionRate=>0}}

The numbers may vary based on the repository
