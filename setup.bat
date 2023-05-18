mkdir workdir
cd workdir
git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git
export PATH=`pwd`/depot_tools:$PATH

cd depot_tools
gclient

mkdir webrtc_checkout
cd webrtc_checkout
fetch --nohooks --no-history webrtc
gclient sync --nohooks --no-history 

cd src
git fetch --all
git checkout -b head_9664 refs/remotes/branch-heads/9664
gclient sync --nohooks --no-history 

SET DEPOT_TOOLS_WIN_TOOLCHAIN=0
gclient runhooks

mkdir ninja_install
curl -L https://github.com/ninja-build/ninja/releases/download/v1.11.1/ninja-win.zip --output ninja-win.zip && unzip ninja-win.zip -d ninja_install

export PATH=`pwd`/depot_tools:$PATH
