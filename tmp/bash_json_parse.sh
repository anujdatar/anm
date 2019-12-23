# curl -s 'https://api.github.com/users/lambda' | jq -r '.name'

nodejs_dist_index="https://nodejs.org/dist/index.json"

curl -s $nodejs_dist_index | jq -r '.[0]'
