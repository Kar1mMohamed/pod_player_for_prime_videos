part of 'pod_getx_video_controller.dart';

class _PodVideoQualityController extends _PodVideoController {
  ///
  int? vimeoPlayingVideoQuality;

  ///vimeo all quality urls
  List<VideoQalityUrls> vimeoOrVideoUrls = [];
  late String _videoQualityUrl;

  Map<String, String> primeVideoHandlersUrls = {};
  String? currentPrimeVideoQuality;

  ///invokes callback from external controller
  VoidCallback? onVimeoVideoQualityChanged;

  ///*vimeo player configs
  ///
  ///get all  `quality urls`
  Future<void> getQualityUrlsFromVimeoId(
    String videoId, {
    String? hash,
  }) async {
    try {
      podVideoStateChanger(PodVideoState.loading);
      final vimeoVideoUrls = await VideoApis.getVimeoVideoQualityUrls(
        videoId,
        hash,
      );

      ///
      vimeoOrVideoUrls = vimeoVideoUrls ?? [];
    } catch (e) {
      rethrow;
    }
  }

  Future<void> getQualityUrlsFromVimeoPrivateId(
    String videoId,
    Map<String, String> httpHeader,
  ) async {
    try {
      podVideoStateChanger(PodVideoState.loading);
      final vimeoVideoUrls =
          await VideoApis.getVimeoPrivateVideoQualityUrls(videoId, httpHeader);

      ///
      vimeoOrVideoUrls = vimeoVideoUrls ?? [];
    } catch (e) {
      rethrow;
    }
  }

  void sortQualityVideoUrls(
    List<VideoQalityUrls>? urls,
  ) {
    final urls0 = urls;

    ///has issues with 240p
    urls0?.removeWhere((element) => element.quality == 240);

    ///has issues with 144p in web
    if (kIsWeb) {
      urls0?.removeWhere((element) => element.quality == 144);
    }

    ///sort
    urls0?.sort((a, b) => a.quality.compareTo(b.quality));

    ///
    vimeoOrVideoUrls = urls0 ?? [];
  }

  ///get vimeo quality `ex: 1080p` url
  VideoQalityUrls getQualityUrl(int quality) {
    return vimeoOrVideoUrls.firstWhere(
      (element) => element.quality == quality,
      orElse: () => vimeoOrVideoUrls.first,
    );
  }

  Future<String> getUrlFromVideoQualityUrls({
    required List<int> qualityList,
    required List<VideoQalityUrls> videoUrls,
  }) async {
    sortQualityVideoUrls(videoUrls);
    if (vimeoOrVideoUrls.isEmpty) {
      throw Exception('videoQuality cannot be empty');
    }

    final fallback = vimeoOrVideoUrls[0];
    VideoQalityUrls? urlWithQuality;
    for (final quality in qualityList) {
      urlWithQuality = vimeoOrVideoUrls.firstWhere(
        (url) => url.quality == quality,
        orElse: () => fallback,
      );

      if (urlWithQuality != fallback) {
        break;
      }
    }

    urlWithQuality ??= fallback;
    _videoQualityUrl = urlWithQuality.url;
    vimeoPlayingVideoQuality = urlWithQuality.quality;
    return _videoQualityUrl;
  }

  Future<String> getUrlFromVideoQualitiesUrlsPrimeVideo({
    required Map<String, String> videoUrls,
  }) async {
    //keys is qualities
    // values is urls

    final qualityList = videoUrls.keys.toList();

    final fallback = videoUrls.entries.first;

    final urlWithQuality = fallback.value;

    final downloadUrlQuality =
        await getDownloadUrlFromPrimeVideo(urlWithQuality!);

    // ignore: join_return_with_assignment
    _videoQualityUrl = downloadUrlQuality;

    primeVideoHandlersUrls = videoUrls;
    currentPrimeVideoQuality = qualityList.first;

    return _videoQualityUrl;
  }

  Future<List<VideoQalityUrls>> getVideoQualityUrlsFromYoutube(
    String youtubeIdOrUrl,
    bool live,
  ) async {
    return await VideoApis.getYoutubeVideoQualityUrls(youtubeIdOrUrl, live) ??
        [];
  }

  Future<void> changeVideoQuality(
      {int? quality, String? primeVideoQuality}) async {
    if (vimeoOrVideoUrls.isEmpty && primeVideoHandlersUrls.isEmpty) {
      throw Exception('videoQuality cannot be empty');
    }
    if (vimeoPlayingVideoQuality != quality) {
      _videoQualityUrl = vimeoOrVideoUrls
          .where((element) => element.quality == quality)
          .first
          .url;
      podLog(_videoQualityUrl);
      vimeoPlayingVideoQuality = quality;
      _videoCtr?.removeListener(videoListner);
      podVideoStateChanger(PodVideoState.paused);
      podVideoStateChanger(PodVideoState.loading);
      playingVideoUrl = _videoQualityUrl;
      _videoCtr = VideoPlayerController.networkUrl(Uri.parse(_videoQualityUrl));
      await _videoCtr?.initialize();
      _videoDuration = _videoCtr?.value.duration ?? Duration.zero;
      _videoCtr?.addListener(videoListner);
      await _videoCtr?.seekTo(_videoPosition);
      setVideoPlayBack(_currentPaybackSpeed);
      podVideoStateChanger(PodVideoState.playing);
      onVimeoVideoQualityChanged?.call();
      update();
      update(['update-all']);
    }
    if (primeVideoHandlersUrls.isNotEmpty && primeVideoQuality != null) {
      if (primeVideoHandlersUrls.containsKey(primeVideoQuality)) {
        // print('primeVideoQuality: $primeVideoQuality');
        final downloadUrlQuality = await getDownloadUrlFromPrimeVideo(
          primeVideoHandlersUrls[primeVideoQuality]!,
        );
        _videoQualityUrl = downloadUrlQuality;
        playingVideoUrl = _videoQualityUrl;
        currentPrimeVideoQuality = primeVideoQuality;
        _videoCtr?.removeListener(videoListner);
        podVideoStateChanger(PodVideoState.paused);
        podVideoStateChanger(PodVideoState.loading);
        final downloadUrl = await getDownloadUrlFromPrimeVideo(
          primeVideoHandlersUrls[primeVideoQuality]!,
        );
        _videoCtr = VideoPlayerController.networkUrl(Uri.parse(downloadUrl));
        await _videoCtr?.initialize();
        _videoDuration = _videoCtr?.value.duration ?? Duration.zero;
        _videoCtr?.addListener(videoListner);
        await _videoCtr?.seekTo(_videoPosition);
        setVideoPlayBack(_currentPaybackSpeed);
        podVideoStateChanger(PodVideoState.playing);
        onVimeoVideoQualityChanged?.call();
        update();
        update(['update-all']);
      }
    }
  }

  Future<String> getDownloadUrlFromPrimeVideo(String handlerUrl) async {
    return read(Uri.parse(handlerUrl))
        .then((e) => jsonDecode(e)['downloadUrl'] as String);
  }
}
