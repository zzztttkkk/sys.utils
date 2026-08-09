export HOMEBREW_BREW_GIT_REMOTE="https://mirrors.ustc.edu.cn/brew.git"
export HOMEBREW_BOTTLE_DOMAIN="https://mirrors.ustc.edu.cn/homebrew-bottles"
export HOMEBREW_API_DOMAIN="https://mirrors.ustc.edu.cn/homebrew-bottles/api"
/bin/bash -c "$(curl -fsSL https://mirrors.ustc.edu.cn/misc/brew-install.sh)"

eval "$(/opt/homebrew/bin/brew shellenv)"

brew update

brew install go node gum powershell

go env -w "GO111MODULE=on"
go env -w "GOPROXY=https://goproxy.cn, direct"

npm config set registry https://mirrors.cloud.tencent.com/npm/
npm i -g pnpm
pnpm c set registry https://mirrors.cloud.tencent.com/npm/
