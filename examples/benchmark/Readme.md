# Usage

+ `bundle exec ../../exe/lowkiq -r ./lowkiq.rb`
+ `bundle exec sidekiq -r ./sidekiq.rb`

# Results

5 threads, 100_000 jobs

+ lowkiq: 214 sec
+ sidekiq: 29 sec
