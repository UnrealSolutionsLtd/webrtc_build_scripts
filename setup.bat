mkdir workdir
cd workdir
git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git
export PATH=`pwd`/depot_tools:$PATH

git config --global http.postBuffer 1048576000

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

export PATH=`pwd`/ninja_install:$PATH

gn gen --ide=vs2019 out/Release_4664 --args="use_rtti=true enable_iterator_debugging=true is_clang=false use_custom_libcxx=false libcxx_is_shared=true enable_iterator_debugging=true enable_libaom=false rtc_build_tools=false rtc_include_tests=false rtc_build_examples=false rtc_build_ssl=false is_debug=false rtc_enable_protobuf=false use_lld=false rtc_include_internal_audio_device=false target_cpu=\"x64\" rtc_ssl_root=<>"