# Windows-specific WebRTC build instructions

## Install Ninja
Download binaries: https://github.com/ninja-build/ninja and add them to PATH!

Or use this code snippet:
```
mkdir ninja_install
curl -L https://github.com/ninja-build/ninja/releases/download/v1.11.1/ninja-win.zip --output ninja-win.zip && unzip ninja-win.zip -d ninja_install
export PATH=`pwd`/ninja_install:$PATH
``` 

## Create working directory
```
mkdir workdir
cd workdir
git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git
export PATH=`pwd`/depot_tools:$PATH
```

**Important**: Make sure there is no Python in PATH! ```where python``` should return path to depot_tools!

## Clone webrtc
```
cd depot_tools
gclient

mkdir webrtc_checkout
cd webrtc_checkout
fetch --nohooks webrtc
gclient sync --nohooks

cd src
git fetch --all
git checkout -b head_9664 refs/remotes/branch-heads/9664

gclient sync --nohooks

SET DEPOT_TOOLS_WIN_TOOLCHAIN=0
gclient runhooks
```


## Generating project files

Define toolchain variable: `SET DEPOT_TOOLS_WIN_TOOLCHAIN=0`

**Note**: All gn gen <...> commands must be called from within `<WEBRTC_CHECKOUT_DIR>/src`


## WebRTC codebase modifications 

First step is to replace all WebRTC .h files with Unreal Engine ones. That is important as we need to exclude H265 codec from compilation.

Comment out `deps += [ "//third_party/boringssl" ]` in `<WEBRTC_CHECKOUT_DIR>/src/rtc_library/BUILD.gn`

Comment out all usages of 
```
SetThreadPriority
SetPriority
rtc::SetCurrentThreadName
``` 
in `<WEBRTC_CHECKOUT_DIR>/src/rtc_library/platform_thread.cc`

Remove `PlatformThread(Handle handle, bool joinable);` if it is present in `<WEBRTC_CHECKOUT_DIR>/src/rtc_library/platform_thread.h`


Add `defines += ["DISABLE_H265", "RTC_DISABLE_LOGGING"]` to `<WEBRTC_CHECKOUT_DIR>/src/BUILD.gn` (in `config("common_inherited_config")`)
```
// Compile via VS 2019 
// Working solution for M96
// Note: h264 codec is not needed as Unreal provides its own solution (via nvenc)
// non-clang is not tested!
// provide path to Unreal Engine 5.1 OpenSSL includes!
// Add PublicDefinitions.Add("DISABLE_H265=1") to WebRTC.Build.cs (Unreal Engine codebase)
```
```
gn gen  --ide=vs2019 out/release_no_h264 --args="target_winuwp_family=\"desktop\" is_component_build=false rtc_include_tests=false rtc_use_h264=false use_rtti=true enable_google_benchmarks=false rtc_disable_logging=true treat_warnings_as_errors=false is_clang=true rtc_include_ilbc=false use_custom_libcxx=false rtc_build_ssl=false is_debug=false rtc_enable_protobuf=false rtc_build_examples=false use_lld=false rtc_include_internal_audio_device=false rtc_builtin_ssl_root_certificates=false enable_libaom=false target_cpu=\"x64\" rtc_ssl_root=\"E:\mawari_workspace\UnrealEngine-5.1.1-release\Engine\Source\ThirdParty\OpenSSL\1.1.1n\include\Win64\VS2015\""
```


Compiling via Ninja: 
```ninja -C out/release_no_h264```



Hint: Main cause of runtime errors (i.e. copy contructor/asssignment operator) -> Misalignment between size of VideoCodec structure in headers and compiled static library.  Adding PublicDefinitions.Add("DISABLE_H265=1") helped to resolve the runtime errors.




gn gen --ide=vs2019 out/Release_4664_no_opus --args="use_rtti=true enable_iterator_debugging=true is_clang=false use_custom_libcxx=false libcxx_is_shared=true enable_libaom=false rtc_build_tools=false rtc_include_tests=false rtc_build_examples=false rtc_build_ssl=false is_debug=false rtc_enable_protobuf=false use_lld=false rtc_include_internal_audio_device=false target_cpu=\"x64\" rtc_ssl_root=\"E:\mawari_workspace\UnrealEngine-5.1.1-release\Engine\Source\ThirdParty\OpenSSL\1.1.1n\include\Win64\VS2015\""

# symbol export & opus
gn gen --ide=vs2019 out/Release_4664_symbols_export --args="use_rtti=true enable_iterator_debugging=true is_clang=false rtc_include_opus=true rtc_build_opus=true rtc_enable_symbol_export=true rtc_enable_objc_symbol_export=false  use_custom_libcxx=false libcxx_is_shared=true enable_libaom=false rtc_build_tools=false rtc_include_tests=false rtc_build_examples=false rtc_build_ssl=false is_debug=false rtc_enable_protobuf=false use_lld=false rtc_include_internal_audio_device=false target_cpu=\"x64\" rtc_ssl_root=\"E:\mawari_workspace\UnrealEngine-5.1.1-release\Engine\Source\ThirdParty\OpenSSL\1.1.1n\include\Win64\VS2015\""


# latest (can link with source changes + abseil ones)
gn gen --ide=vs2019 out/Release_4664_no_pch --args="use_rtti=true enable_iterator_debugging=true is_clang=false rtc_include_opus=true rtc_build_opus=true enable_precompiled_headers=false use_custom_libcxx=false libcxx_is_shared=true  enable_libaom=false rtc_build_tools=false rtc_include_tests=false rtc_build_examples=false rtc_build_ssl=false is_debug=false rtc_enable_protobuf=false use_lld=false rtc_include_internal_audio_device=false target_cpu=\"x64\" rtc_ssl_root=\"E:\mawari_workspace\UnrealEngine-5.1.1-release\Engine\Source\ThirdParty\OpenSSL\1.1.1n\include\Win64\VS2015\""

# enable proprietary codecs (can link, runtime error, video codec access violation!)
gn gen --ide=vs2019 out/Release_4664_proprietary_codecs --args="use_rtti=true enable_iterator_debugging=true is_clang=false rtc_include_opus=true proprietary_codecs=true rtc_build_opus=true enable_precompiled_headers=false use_custom_libcxx=false libcxx_is_shared=true enable_libaom=false rtc_build_tools=false rtc_include_tests=false rtc_build_examples=false rtc_build_ssl=false rtc_builtin_ssl_root_certificates=false rtc_use_absl_mutex=true is_debug=false rtc_enable_protobuf=false use_lld=false rtc_include_internal_audio_device=false target_cpu=\"x64\" rtc_ssl_root=\"E:\mawari_workspace\UnrealEngine-5.1.1-release\Engine\Source\ThirdParty\OpenSSL\1.1.1n\include\Win64\VS2015\""

# enable h264 (can link, runtime error, video codec access violation!)
gn gen --ide=vs2019 out/Release_4664_proprietary_codecs --args="use_rtti=true enable_iterator_debugging=true is_clang=false rtc_include_opus=true proprietary_codecs=true rtc_use_h264=true rtc_build_opus=true use_custom_libcxx=false libcxx_is_shared=true enable_libaom=false rtc_build_tools=false rtc_include_tests=false rtc_build_examples=false rtc_build_ssl=false rtc_builtin_ssl_root_certificates=false rtc_use_absl_mutex=true is_debug=false rtc_enable_protobuf=false use_lld=false rtc_include_internal_audio_device=false target_cpu=\"x64\" rtc_ssl_root=\"E:\mawari_workspace\UnrealEngine-5.1.1-release\Engine\Source\ThirdParty\OpenSSL\1.1.1n\include\Win64\VS2015\""


# latest working 19.05 (still runtime error)

gn gen --ide=vs2019 out/Release_4664_h264_support_ffmpeg_unsafe_atomics --args="use_rtti=true enable_iterator_debugging=true is_clang=false rtc_include_opus=true proprietary_codecs=true rtc_use_h264=true rtc_build_opus=true use_custom_libcxx=false libcxx_is_shared=true enable_libaom=false rtc_build_tools=false rtc_include_tests=false rtc_build_examples=false rtc_build_ssl=false rtc_builtin_ssl_root_certificates=false rtc_use_absl_mutex=true is_debug=false rtc_enable_protobuf=false use_lld=false rtc_include_internal_audio_device=false target_cpu=\"x64\" rtc_ssl_root=\"E:\mawari_workspace\UnrealEngine-5.1.1-release\Engine\Source\ThirdParty\OpenSSL\1.1.1n\include\Win64\VS2015\""


# test gn gen --ide=vs2019 out/Release_4664_test_flags --args="use_rtti=true is_clang=false rtc_include_opus=true proprietary_codecs=true rtc_use_h264=true rtc_build_opus=true use_custom_libcxx=false libcxx_is_shared=false enable_iterator_debugging=true enable_libaom=false rtc_build_tools=false rtc_include_tests=false rtc_include_pulse_audio=false rtc_include_ilbc=false  rtc_build_examples=false rtc_build_ssl=false rtc_builtin_ssl_root_certificates=false rtc_use_absl_mutex=true is_debug=false rtc_enable_protobuf=false use_lld=false rtc_include_internal_audio_device=false target_cpu=\"x64\" rtc_ssl_root=\"E:\mawari_workspace\UnrealEngine-5.1.1-release\Engine\Source\ThirdParty\OpenSSL\1.1.1n\include\Win64\VS2015\""


Look into https://groups.google.com/g/discuss-webrtc/c/YZaNOPdWG2Y/m/6SSEV1OKCgAJ




# Current errors (happened because of ABSL OPTIONS.h -> need to modify options.h to use absl implementations!
# Go to third_party\abseil-cpp\absl\base\options.h and switch to use only absl implementations for EVERYTHING
8>Module.PixelStreaming.cpp.obj : error LNK2019: unresolved external symbol "public: static class absl::optional<struct webrtc::AudioDecoderOpus::Config> __cdecl webrtc::AudioDecoderOpus::SdpToConfig(struct webrtc::SdpAudioFormat const &)" (?SdpToConfig@AudioDecoderOpus@webrtc@@SA?AV?$optional@UConfig@AudioDecoderOpus@webrtc@@@absl@@AEBUSdpAudioFormat@2@@Z) referenced in function "public: virtual bool __cdecl webrtc::audio_decoder_factory_template_impl::AudioDecoderFactoryT<struct webrtc::AudioDecoderOpus>::IsSupportedDecoder(struct webrtc::SdpAudioFormat const &)" (?IsSupportedDecoder@?$AudioDecoderFactoryT@UAudioDecoderOpus@webrtc@@@audio_decoder_factory_template_impl@webrtc@@UEAA_NAEBUSdpAudioFormat@3@@Z)
8>Module.PixelStreaming.cpp.obj : error LNK2019: unresolved external symbol "public: static class std::unique_ptr<class webrtc::AudioDecoder,struct std::default_delete<class webrtc::AudioDecoder> > __cdecl webrtc::AudioDecoderOpus::MakeAudioDecoder(struct webrtc::AudioDecoderOpus::Config,class absl::optional<class webrtc::AudioCodecPairId>)" (?MakeAudioDecoder@AudioDecoderOpus@webrtc@@SA?AV?$unique_ptr@VAudioDecoder@webrtc@@U?$default_delete@VAudioDecoder@webrtc@@@std@@@std@@UConfig@12@V?$optional@VAudioCodecPairId@webrtc@@@absl@@@Z) referenced in function "public: virtual class std::unique_ptr<class webrtc::AudioDecoder,struct std::default_delete<class webrtc::AudioDecoder> > __cdecl webrtc::audio_decoder_factory_template_impl::AudioDecoderFactoryT<struct webrtc::AudioDecoderOpus>::MakeAudioDecoder(struct webrtc::SdpAudioFormat const &,class absl::optional<class webrtc::AudioCodecPairId>)" (?MakeAudioDecoder@?$AudioDecoderFactoryT@UAudioDecoderOpus@webrtc@@@audio_decoder_factory_template_impl@webrtc@@UEAA?AV?$unique_ptr@VAudioDecoder@webrtc@@U?$default_delete@VAudioDecoder@webrtc@@@std@@@std@@AEBUSdpAudioFormat@3@V?$optional@VAudioCodecPairId@webrtc@@@absl@@@Z)
8>Module.PixelStreaming.cpp.obj : error LNK2019: unresolved external symbol "public: static class absl::optional<struct webrtc::AudioEncoderOpusConfig> __cdecl webrtc::AudioEncoderOpus::SdpToConfig(struct webrtc::SdpAudioFormat const &)" (?SdpToConfig@AudioEncoderOpus@webrtc@@SA?AV?$optional@UAudioEncoderOpusConfig@webrtc@@@absl@@AEBUSdpAudioFormat@2@@Z) referenced in function "public: static class std::unique_ptr<class webrtc::AudioEncoder,struct std::default_delete<class webrtc::AudioEncoder> > __cdecl webrtc::audio_encoder_factory_template_impl::Helper<struct webrtc::AudioEncoderOpus>::MakeAudioEncoder(int,struct webrtc::SdpAudioFormat const &,class absl::optional<class webrtc::AudioCodecPairId>)" (?MakeAudioEncoder@?$Helper@UAudioEncoderOpus@webrtc@@@audio_encoder_factory_template_impl@webrtc@@SA?AV?$unique_ptr@VAudioEncoder@webrtc@@U?$default_delete@VAudioEncoder@webrtc@@@std@@@std@@HAEBUSdpAudioFormat@3@V?$optional@VAudioCodecPairId@webrtc@@@absl@@@Z)
8>Module.PixelStreaming.cpp.obj : error LNK2019: unresolved external symbol "public: static class std::unique_ptr<class webrtc::AudioEncoder,struct std::default_delete<class webrtc::AudioEncoder> > __cdecl webrtc::AudioEncoderOpus::MakeAudioEncoder(struct webrtc::AudioEncoderOpusConfig const &,int,class absl::optional<class webrtc::AudioCodecPairId>)" (?MakeAudioEncoder@AudioEncoderOpus@webrtc@@SA?AV?$unique_ptr@VAudioEncoder@webrtc@@U?$default_delete@VAudioEncoder@webrtc@@@std@@@std@@AEBUAudioEncoderOpusConfig@2@HV?$optional@VAudioCodecPairId@webrtc@@@absl@@@Z) referenced in function "public: static class std::unique_ptr<class webrtc::AudioEncoder,struct std::default_delete<class webrtc::AudioEncoder> > __cdecl webrtc::audio_encoder_factory_template_impl::Helper<struct webrtc::AudioEncoderOpus>::MakeAudioEncoder(int,struct webrtc::SdpAudioFormat const &,class absl::optional<class webrtc::AudioCodecPairId>)" (?MakeAudioEncoder@?$Helper@UAudioEncoderOpus@webrtc@@@audio_encoder_factory_template_impl@webrtc@@SA?AV?$unique_ptr@VAudioEncoder@webrtc@@U?$default_delete@VAudioEncoder@webrtc@@@std@@@std@@HAEBUSdpAudioFormat@3@V?$optional@VAudioCodecPairId@webrtc@@@absl@@@Z)
8>Module.PixelStreaming.cpp.obj : error LNK2019: unresolved external symbol "class absl::optional<class std::basic_string<char,struct std::char_traits<char>,class std::allocator<char> > > __cdecl webrtc::H264ProfileLevelIdToString(struct webrtc::H264ProfileLevelId const &)" (?H264ProfileLevelIdToString@webrtc@@YA?AV?$optional@V?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@@absl@@AEBUH264ProfileLevelId@1@@Z) referenced in function "struct webrtc::SdpVideoFormat __cdecl UE::PixelStreaming::CreateH264Format(enum webrtc::H264Profile,enum webrtc::H264Level)" (?CreateH264Format@PixelStreaming@UE@@YA?AUSdpVideoFormat@webrtc@@W4H264Profile@4@W4H264Level@4@@Z)
8>Module.PixelStreaming.cpp.obj : error LNK2019: unresolved external symbol "bool __cdecl absl::EqualsIgnoreCase(class absl::string_view,class absl::string_view)" (?EqualsIgnoreCase@absl@@YA_NVstring_view@1@0@Z) referenced in function "public: virtual class std::unique_ptr<class webrtc::VideoDecoder,struct std::default_delete<class webrtc::VideoDecoder> > __cdecl UE::PixelStreaming::FVideoDecoderFactory::CreateVideoDecoder(struct webrtc::SdpVideoFormat const &)" (?CreateVideoDecoder@FVideoDecoderFactory@PixelStreaming@UE@@UEAA?AV?$unique_ptr@VVideoDecoder@webrtc@@U?$default_delete@VVideoDecoder@webrtc@@@std@@@std@@AEBUSdpVideoFormat@webrtc@@@Z)



COMMENT OUT!!!
third_party/usrsctp/usrsctplib/usrsctplib/ -> 
../../third_party/usrsctp/usrsctplib/usrsctplib/user_environment.c(102,2): error: Only BoringSSL is supported with SCTP_USE_OPENSSL_RAND.
#error Only BoringSSL is supported with SCTP_USE_OPENSSL_RAND



Enable ffmpeg unsafe atomics (IMPORTANT)!!! Only if H264 codec is required!




WORKING COMPILATION VIA CLANG for 4884
TODO: Need to include h264 and proprietary codecs??? NO need to include h264 as Unreal provides its own implementation


E:\mawari_workspace\depot_tools\webrtc_checkout_4844\src>gn gen out/release_no_boringssl --args="target_winuwp_family=\"desktop\" is_component_build=false rtc_include_tests=false rtc_use_h264=true use_rtti=true treat_warnings_as_errors=false is_clang=true use_custom_libcxx=false rtc_build_ssl=false is_debug=false rtc_enable_protobuf=false rtc_build_examples=false use_lld=false rtc_include_internal_audio_device=false rtc_builtin_ssl_root_certificates=false enable_libaom=false target_cpu=\"x64\" rtc_ssl_root=\"E:\mawari_workspace\UnrealEngine-5.1.1-release\Engine\Source\ThirdParty\OpenSSL\1.1.1n\include\Win64\VS2015\""





M96
E:\mawari_workspace\depot_tools\webrtc_checkout\src>gn gen out/release_test --filters=//:webrtc  --args="is_component_build=false rtc_include_tests=false rtc_include_ilbc=false use_rtti=true enable_google_benchmarks=false treat_warnings_as_errors=false enable_iterator_debugging=false use_custom_libcxx=false libcxx_is_shared=true rtc_build_ssl=false is_debug=false rtc_enable_protobuf=false rtc_build_examples=false use_lld=false rtc_include_internal_audio_device=false rtc_builtin_ssl_root_certificates=false enable_libaom=false target_cpu=\"x64\" rtc_ssl_root=\"E:\mawari_workspace\UnrealEngine-5.1.1-release\Engine\Source\ThirdParty\OpenSSL\1.1.1n\include\Win64\VS2015\""


M96 (clang true)

gn gen out/release_test --filters=//:webrtc  --args="is_component_build=false rtc_include_tests=false rtc_include_ilbc=false use_rtti=true rtc_use_h264=true proprietary_codecs=true  enable_google_benchmarks=false treat_warnings_as_errors=false enable_iterator_debugging=false use_custom_libcxx=false libcxx_is_shared=true rtc_build_ssl=false is_debug=false rtc_enable_protobuf=false rtc_build_examples=false use_lld=false rtc_include_internal_audio_device=false rtc_builtin_ssl_root_certificates=false enable_libaom=false target_cpu=\"x64\" rtc_ssl_root=\"E:\mawari_workspace\UnrealEngine-5.1.1-release\Engine\Source\ThirdParty\OpenSSL\1.1.1n\include\Win64\VS2015\""


# Main cause of runtime errors (i.e. copy contructor/asssignment operator) -> Misalignment between size of VideoCodec structure in headers and static library???
# Adding PublicDefinitions.Add("DISABLE_H265=1") helped to resolve the runtime errors.

# Working solution for M96
# Note: h264 codec is not needed as Unreal provides its own solution (via nvenc)
# non-clang is not tested!
# PASS DISABLE_H265=1 in WebRTC.Build.cs
gn gen  --ide=vs2019 out/release_no_h264 --args="target_winuwp_family=\"desktop\" is_component_build=false rtc_include_tests=false rtc_use_h264=false use_rtti=true enable_google_benchmarks=false rtc_disable_logging=true treat_warnings_as_errors=false is_clang=true rtc_include_ilbc=false use_custom_libcxx=false rtc_build_ssl=false is_debug=false rtc_enable_protobuf=false rtc_build_examples=false use_lld=false rtc_include_internal_audio_device=false rtc_builtin_ssl_root_certificates=false enable_libaom=false target_cpu=\"x64\" rtc_ssl_root=\"E:\mawari_workspace\UnrealEngine-5.1.1-release\Engine\Source\ThirdParty\OpenSSL\1.1.1n\include\Win64\VS2015\""


# Compile via Ninja 
# or open VS sln and compile there
ninja -C out/release_no_h264_tests

