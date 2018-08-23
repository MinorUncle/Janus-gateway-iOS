//
//  VideoCallViewController.m
//  GJJanusDemo
//
//  Created by melot on 2018/3/20.
//  Copyright © 2018年 MirrorUncle. All rights reserved.
//

#import "VideoCallViewController.h"
#import "GJJanusVideoRoom.h"
#import "ZipArchive.h"

//#define ROOM_ID 19911024
#define ROOM_ID 1234

//#error 请自行搭建janus服务器。https://janus.conf.meetecho.com/index.html
#define SERVER_ADDR @"ws://192.168.0.145:8188"

@interface GJSliderView:UISlider{
    UILabel * _titleLab;
    UILabel * _valueLab;

}
@property(nonatomic,copy)NSString* title;
@end
@implementation GJSliderView
-(instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        _titleLab = [[UILabel alloc]init];
        [_titleLab setFont:[UIFont systemFontOfSize:15]];
        [_titleLab setTextColor:[UIColor whiteColor]];
        [_titleLab setTextAlignment:NSTextAlignmentCenter];
        [self addSubview:_titleLab];
        _valueLab = [[UILabel alloc]init];
        [_valueLab setFont:[UIFont systemFontOfSize:12]];
        [_valueLab setTextAlignment:NSTextAlignmentCenter];
        [_valueLab setTextColor:[UIColor whiteColor]];
        self.value = 0;
        [self addSubview:_valueLab];
    
    }
    return self;
}

-(void)setValue:(float)value{
    [super setValue:value];
    _valueLab.text = [NSString stringWithFormat:@"%0.2f",value];
}

-(void)setValue:(float)value animated:(BOOL)animated{
    [super setValue:value animated:animated];
    _valueLab.text = [NSString stringWithFormat:@"%0.2f",value];
}
#define xRate 0.3
#define yRate 0.5

-(void)setFrame:(CGRect)frame{
    [super setFrame:frame];
    CGRect rect = frame;
    rect.origin = CGPointZero;
    rect.size.width = frame.size.width * xRate;
    _titleLab.frame = rect;
    
    rect.origin.x = CGRectGetMaxX(rect);
    rect.size.width = frame.size.width*(1-xRate);
    rect.size.height = frame.size.height * yRate;
    _valueLab.frame = rect;
}

-(void)setTitle:(NSString *)title{
    [_titleLab setText:title];
}

-(NSString *)title{
    return _titleLab.text;
}

-(CGRect)trackRectForBounds:(CGRect)bounds{
    CGRect rect = bounds;
    rect.size.height = 3;
    rect.size.width = bounds.size.width * (1-xRate);
    rect.origin.x = bounds.size.width - rect.size.width;
    rect.origin.y = (bounds.size.height - rect.size.height)* yRate;
    return rect;
};

@end

@interface GJVideoBoxView:UIView
{
    CGPoint _startPoint;
    CGRect _startFrame;
    UITapGestureRecognizer* _tapGesture;
    CGRect _originFrame;
}
@end
@implementation GJVideoBoxView

-(instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        _tapGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tap:)];
        [_tapGesture setNumberOfTapsRequired:2];
        [self addGestureRecognizer:_tapGesture];
    }
    return self;
}
-(void)tap:(UITapGestureRecognizer*)reg{
    if (self.superview) {
        if (CGRectEqualToRect(self.frame, self.superview.frame)) {
            [UIView animateWithDuration:0.2 animations:^{
                self.frame = _originFrame;
            }];
        }else{
            _originFrame = self.frame;
            [UIView animateWithDuration:0.2 animations:^{
                self.frame = self.superview.frame;
            }];
        }
    }
}

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    if (self.superview) {
        _startPoint = [touches.anyObject  locationInView:self.superview];
        _startFrame = self.frame;
    }else{
        _startPoint = CGPointMake(-1, -1);
    }
}
-(void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    if (_startPoint.x > 0) {
        CGPoint point = [touches.anyObject locationInView:self.superview];
        CGFloat offestX = point.x - _startPoint.x;
        CGFloat offestY = point.y - _startPoint.y;
        CGRect frame = _startFrame;
        frame.origin.x += offestX;
        frame.origin.y += offestY;
        self.frame = frame;
    }
}

-(void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    
}

-(void)dealloc{
    [self removeGestureRecognizer:_tapGesture];
}
@end

@interface VideoCallViewController ()<GJJanusVideoRoomDelegate>{
    UIScrollView* _controlView;
    
    UIButton* _startBtn;
    UIButton* _switchCameraBtn;
    UIButton* _streamMirrorBtn;
    UIButton* _previewMirrorBtn;
    UIButton* _startStickerBtn;
    UIButton* _sizeChange;
    NSMutableArray<UIView*>* _controlBtns;
    NSArray<NSString*>* _stickerPath;
    NSDictionary* _pushSize;
    UIButton* _faceStickerBtn;
    UIButton* _videoOrientationBtn;

    
    GJSliderView* _brigntSlider;
    GJSliderView* _rubbySlider;
    GJSliderView* _softenSlider;
    GJSliderView* _slenderSlider;
    GJSliderView* _enlargementSlider;

}
@property(retain,nonatomic)GJJanusVideoRoom* videoRoom;
@property(retain,nonatomic)UIButton* exitBtn;
@property(retain,nonatomic)UIView* localView;
@property(retain,nonatomic)NSMutableDictionary<NSNumber*,KKRTCCanvas*>* remotes;
@end

@implementation VideoCallViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    if ([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
        self.navigationController.interactivePopGestureRecognizer.enabled = NO;
    }  
    NSURL * server = [NSURL URLWithString:SERVER_ADDR];
//    NSURL * server = [NSURL URLWithString:@"ws://10.0.21.232:8188"];

    _videoRoom = [GJJanusVideoRoom shareInstanceWithServer:server delegate:self];
    _remotes = [NSMutableDictionary dictionaryWithCapacity:2];
    _controlBtns = [NSMutableArray arrayWithCapacity:2];
    _pushSize = @{@"360*640":[NSValue valueWithCGSize:CGSizeMake(360, 640)],
                  @"720*960":[NSValue valueWithCGSize:CGSizeMake(720, 960)],
                  @"640*480":[NSValue valueWithCGSize:CGSizeMake(640, 480)],
                  };
    _stickerPath = @[@"bear",@"bd",@"hkbs",@"lb",@"null"];

    GJJanusPushlishMediaConstraints* localConfig = [[GJJanusPushlishMediaConstraints alloc]init];
    localConfig.pushSize = [_pushSize.allValues[_sizeChange.tag % _pushSize.count] CGSizeValue];
    localConfig.fps = 15;
    localConfig.videoBitrate = 600*1000;
    localConfig.audioBitrate = 200*1000;
    localConfig.frequency = 44100;
    //    localConfig.audioEnable = NO;
    _videoRoom.localConfig = localConfig;
//    NSString* path = [[NSBundle mainBundle]pathForResource:@"track_data" ofType:@"dat"];
//    [_videoRoom prepareVideoEffectWithBaseData:path];
    [self buildUI];
    [self updateFrame];
//    [_videoRoom joinRoomWithRoomID:ROOM_ID userName:_userName completeCallback:nil];
    // Do any additional setup after loading the view.
}
-(void)dealloc{
    [_videoRoom chanceVideoEffect];
    [_videoRoom chanceSticker];
}
-(void)buildUI{
    _localView = [[UIView alloc]initWithFrame:self.view.bounds];
    _localView.userInteractionEnabled = NO;
    [self.view addSubview:_localView];
    
    _controlView = [[UIScrollView alloc]init];
    _controlView.pagingEnabled = YES;
    _controlView.showsHorizontalScrollIndicator = NO;
    [self.view addSubview:_controlView];
    
    _startBtn = [[UIButton alloc]init];
    [_startBtn setTitle:@"开始推流" forState:UIControlStateNormal];
    [_startBtn setTitle:@"结束推流" forState:UIControlStateSelected];
    [_startBtn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [_previewMirrorBtn setTitleColor:[UIColor blackColor] forState:UIControlStateSelected];
    [_startBtn addTarget:self action:@selector(btnSelect:) forControlEvents:UIControlEventTouchUpInside];
    [_controlView addSubview:_startBtn];
    [_controlBtns addObject:_startBtn];
    
    _previewMirrorBtn = [[UIButton alloc]init];
    [_previewMirrorBtn setTitle:@"预览镜像" forState:UIControlStateNormal];
    [_previewMirrorBtn setTitleColor:[UIColor blackColor] forState:UIControlStateSelected];
    [_previewMirrorBtn addTarget:self action:@selector(btnSelect:) forControlEvents:UIControlEventTouchUpInside];
    [_controlView addSubview:_previewMirrorBtn];
    [_controlBtns addObject:_previewMirrorBtn];
    
    _streamMirrorBtn = [[UIButton alloc]init];
    [_streamMirrorBtn setTitle:@"推流镜像" forState:UIControlStateNormal];
    [_streamMirrorBtn setTitleColor:[UIColor blackColor] forState:UIControlStateSelected];
    [_streamMirrorBtn addTarget:self action:@selector(btnSelect:) forControlEvents:UIControlEventTouchUpInside];
    [_controlView addSubview:_streamMirrorBtn];
    [_controlBtns addObject:_streamMirrorBtn];
    
    _videoOrientationBtn = [[UIButton alloc]init];
    [_videoOrientationBtn setTitle:@"视图方向:正" forState:UIControlStateNormal];
    [_videoOrientationBtn addTarget:self action:@selector(btnSelect:) forControlEvents:UIControlEventTouchUpInside];
    [_controlView addSubview:_videoOrientationBtn];
    [_controlBtns addObject:_videoOrientationBtn];
    
    _switchCameraBtn = [[UIButton alloc]init];
    [_switchCameraBtn setTitle:@"切换相机" forState:UIControlStateNormal];
    [_switchCameraBtn setTitleColor:[UIColor blackColor] forState:UIControlStateSelected];
    [_switchCameraBtn addTarget:self action:@selector(btnSelect:) forControlEvents:UIControlEventTouchUpInside];
    [_controlView addSubview:_switchCameraBtn];
    [_controlBtns addObject:_switchCameraBtn];
    
    _sizeChange = [[UIButton alloc]init];
    [_sizeChange setTitle:_pushSize.allKeys[_sizeChange.tag%_pushSize.count] forState:UIControlStateNormal];
    [_sizeChange addTarget:self action:@selector(btnSelect:) forControlEvents:UIControlEventTouchUpInside];
    [_controlView addSubview:_sizeChange];
    [_controlBtns addObject:_sizeChange];
    
    _startStickerBtn = [[UIButton alloc]init];
    [_startStickerBtn setTitle:@"开始贴图" forState:UIControlStateNormal];
    [_startStickerBtn setTitle:@"结束贴图" forState:UIControlStateSelected];
    [_startStickerBtn setTitleColor:[UIColor blackColor] forState:UIControlStateSelected];
    [_startStickerBtn addTarget:self action:@selector(btnSelect:) forControlEvents:UIControlEventTouchUpInside];
    [_controlView addSubview:_startStickerBtn];
    [_controlBtns addObject:_startStickerBtn];
    
    _faceStickerBtn = [[UIButton alloc]init];
    [_faceStickerBtn setTitle:@"人脸贴图:无" forState:UIControlStateNormal];
    [_faceStickerBtn addTarget:self action:@selector(btnSelect:) forControlEvents:UIControlEventTouchUpInside];
    [_controlView addSubview:_faceStickerBtn];
    [_controlBtns addObject:_faceStickerBtn];
    
    _brigntSlider = [[GJSliderView alloc]init];
    [_brigntSlider setTitle:@"美白:"];
    [_brigntSlider addTarget:self action:@selector(sliderScroll:) forControlEvents:UIControlEventValueChanged];
    [_controlView addSubview:_brigntSlider];
    [_controlBtns addObject:_brigntSlider];
    
    _softenSlider = [[GJSliderView alloc]init];
    [_softenSlider setTitle:@"磨皮:"];
    [_softenSlider addTarget:self action:@selector(sliderScroll:) forControlEvents:UIControlEventValueChanged];
    [_controlView addSubview:_softenSlider];
    [_controlBtns addObject:_softenSlider];

    _rubbySlider = [[GJSliderView alloc]init];
    [_rubbySlider setTitle:@"红润:"];
    [_rubbySlider addTarget:self action:@selector(sliderScroll:) forControlEvents:UIControlEventValueChanged];
    [_controlView addSubview:_rubbySlider];
    [_controlBtns addObject:_rubbySlider];
    
    _slenderSlider = [[GJSliderView alloc]init];
    [_slenderSlider setTitle:@"瘦脸:"];
    [_slenderSlider addTarget:self action:@selector(sliderScroll:) forControlEvents:UIControlEventValueChanged];
    [_controlView addSubview:_slenderSlider];
    [_controlBtns addObject:_slenderSlider];
    
    _enlargementSlider = [[GJSliderView alloc]init];
    [_enlargementSlider setTitle:@"大眼:"];
    [_enlargementSlider addTarget:self action:@selector(sliderScroll:) forControlEvents:UIControlEventValueChanged];
    [_controlView addSubview:_enlargementSlider];
    [_controlBtns addObject:_enlargementSlider];
    
}

-(void)updateFrame{
    CGRect rect = self.view.bounds;
    _localView.frame = rect;
    rect.size.height *= 0.4;
    rect.origin.y = 64;
    _controlView.frame = rect;
    
    NSInteger maxHCount = 4,maxWCount = 3;
    CGSize itemSize;
    NSInteger wMarggin = 10, hMarggin = 10;
    itemSize.height = (_controlView.frame.size.height - hMarggin*(maxHCount+1))/ maxHCount;
    itemSize.width = (_controlView.frame.size.width - wMarggin*(maxWCount+1))/ maxWCount;
    rect.origin = CGPointZero;
    rect.size = itemSize;
    
    _controlView.contentSize = CGSizeMake(_controlView.frame.size.width*((_controlBtns.count-1)/(maxHCount*maxWCount)+1), _controlView.frame.size.height);
    
    for (int i = 0; i<_controlBtns.count; i++) {
        rect.origin.x = wMarggin + (itemSize.width + wMarggin)*(i/maxHCount);
        rect.origin.y = hMarggin + (itemSize.height + hMarggin)*(i%maxHCount);
        _controlBtns[i].frame = rect;
    }
}

-(void)sliderScroll:(GJSliderView*)slider{

    if(slider == _brigntSlider){
        _videoRoom.skinBright = slider.value * 100;
    }else if (slider == _rubbySlider){
        _videoRoom.skinRuddy = slider.value * 100;
        
    }else if (slider == _softenSlider){
        _videoRoom.skinSoften = slider.value * 100;

    }else if (slider == _slenderSlider){
        _videoRoom.faceSlender = slider.value * 100;

    }else if (slider == _enlargementSlider){
        _videoRoom.eyeEnlargement = slider.value * 100;
    }else{
        assert(0);
    }
}

-(void)btnSelect:(UIButton*)btn{
    btn.selected = !btn.selected;
    if (btn == _startBtn) {
        _sizeChange.enabled = !btn.selected;
        if (btn.selected) {
            
            
            GJJanusPushlishMediaConstraints* localConfig = _videoRoom.localConfig;
            localConfig.pushSize = [_pushSize.allValues[_sizeChange.tag % _pushSize.count] CGSizeValue];
//            localConfig.fps = 15;
//            localConfig.videoBitrate = 600*1000;
//            localConfig.audioBitrate = 200*1000;
//            localConfig.frequency = 44100;
//            //    localConfig.audioEnable = NO;
//            _videoRoom.localConfig = localConfig;
            
            [_videoRoom joinRoomWithRoomID:ROOM_ID userName:_userName completeCallback:^(BOOL isSuccess, NSError *error) {
                if(isSuccess == NO)btn.selected = NO;
                NSLog(@"joinRoomWithRoomID:%@", error);
            }];
        }else{
            [_videoRoom leaveRoom:^{
                
            }];
        }

    }else if (btn == _previewMirrorBtn){
        _videoRoom.previewMirror = btn.selected;
    }else if(btn == _streamMirrorBtn){
        _videoRoom.streamMirror = btn.selected;
    }else if(btn == _switchCameraBtn){
        if (_videoRoom.cameraPosition == AVCaptureDevicePositionBack) {
            _videoRoom.cameraPosition =  AVCaptureDevicePositionFront;
        }else{
            _videoRoom.cameraPosition =  AVCaptureDevicePositionBack;
        }
    }else if (btn == _sizeChange){
        _sizeChange.tag ++;
        [_sizeChange setTitle:_pushSize.allKeys[_sizeChange.tag%_pushSize.count] forState:UIControlStateNormal];
        GJJanusPushlishMediaConstraints* localConfig = _videoRoom.localConfig;
        localConfig.pushSize = [_pushSize.allValues[_sizeChange.tag % _pushSize.count] CGSizeValue];
        _videoRoom.localConfig = localConfig;
    }else  if (btn == _videoOrientationBtn){
        _videoOrientationBtn.tag++;
        _videoRoom.outOrientation = _videoOrientationBtn.tag % 4 + 1;
        switch (_videoRoom.outOrientation) {
            case UIInterfaceOrientationPortrait:
                [_videoOrientationBtn setTitle:@"视图方向:正" forState:UIControlStateNormal];
                break;
            case UIInterfaceOrientationPortraitUpsideDown:
                [_videoOrientationBtn setTitle:@"视图方向:倒" forState:UIControlStateNormal];
                break;
            case UIInterfaceOrientationLandscapeLeft:
                [_videoOrientationBtn setTitle:@"视图方向:左" forState:UIControlStateNormal];
                break;
            case UIInterfaceOrientationLandscapeRight:
                [_videoOrientationBtn setTitle:@"视图方向:右" forState:UIControlStateNormal];
                break;
                
            default:
                assert(0);
                break;
        }
    }else if (btn == _startStickerBtn){
        if (btn.selected) {
            CGRect rect = CGRectMake(0, 0, 200, 50);
            NSMutableArray<GJOverlayAttribute*>* overlays = [NSMutableArray arrayWithCapacity:6];
            CGRect frame = {250,360,rect.size.width,rect.size.height};
            for (int i = 0; i< 1; i++) {
                overlays[0] = [GJOverlayAttribute overlayAttributeWithImage:[self getSnapshotImageWithSize:rect.size] frame:frame rotate:0];
            }
            __weak VideoCallViewController* wkSelf = self;
            
            [_videoRoom startStickerWithImages:overlays fps:15 updateBlock:^(NSInteger index, GJOverlayAttribute * _Nonnull ioAttr, BOOL * _Nonnull ioFinish) {
                *ioFinish = NO;
                if (*ioFinish) {
                    btn.selected = NO;
                }
                static CGFloat r;
                r += 1;
                UIImage* image = [wkSelf getSnapshotImageWithSize:rect.size];
                if (image) {
                    ioAttr.image = image;
                }
                ioAttr.rotate = r;
            }];
        }else{
            [_videoRoom chanceSticker];
        }

    }else if (btn == _faceStickerBtn){
        NSString* zpath = [[NSBundle mainBundle]pathForResource:_stickerPath[btn.tag%_stickerPath.count] ofType:@"zip"];
        NSString*   unzipPath = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0];
        NSString* destPath = [unzipPath stringByAppendingPathComponent:_stickerPath[btn.tag%_stickerPath.count]];

        BOOL isDir;
        BOOL exist = [[NSFileManager defaultManager] fileExistsAtPath:destPath isDirectory:&isDir];

        if (!exist || !isDir) {
            ZipArchive* zip = [[ZipArchive alloc]init];
            if([zip UnzipOpenFile:zpath]){
                if (![zip UnzipFileTo:unzipPath overWrite:NO]) {
                    printf("error\n");
                }
                [zip UnzipCloseFile];
            };
        }
        
        if (zpath) {
            [_videoRoom updateFaceStickerWithTemplatePath:destPath];
            [_faceStickerBtn setTitle:[NSString stringWithFormat:@"人脸贴图:%@",_stickerPath[btn.tag%_stickerPath.count]] forState:UIControlStateNormal];
        }else{
            [_videoRoom updateFaceStickerWithTemplatePath:nil];
            [_faceStickerBtn setTitle:@"人脸贴图:无" forState:UIControlStateNormal];
        }
        btn.tag ++;
    }else{
        assert(0);
    }
}

-(UIImage*)getSnapshotImageWithSize:(CGSize)size{
    static   NSDateFormatter *formatter ;
    if (formatter == nil) {
        formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"yyyy-MM-dd hh:mm:ss:SSS"];
    }
    
    NSString *dateTime = [formatter stringFromDate:[NSDate date]];
    
    CGRect rect = CGRectMake(0, 0, size.width, size.height);
    NSDictionary* attr = @{NSFontAttributeName:[UIFont systemFontOfSize:16]};
    
    static CGPoint fontPoint ;
    if (fontPoint.y < 0.0001) {
        CGSize fontSize = [dateTime sizeWithAttributes:attr];
        fontPoint.x = (size.width - fontSize.width)*0.5;
        fontPoint.y = (size.height - fontSize.height)*0.5;
    }
    //    _timeLab.text = dateTime;
    UIGraphicsBeginImageContextWithOptions(size, YES, [UIScreen mainScreen].scale);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [UIColor colorWithRed:1 green:1 blue:1 alpha:1].CGColor);
    CGContextFillRect(context, rect);
    //    [dateTime drawInRect:rect withAttributes:attr];
    [dateTime drawAtPoint:fontPoint withAttributes:attr];
    //    [_timeLab drawViewHierarchyInRect:_timeLab.bounds afterScreenUpdates:NO];
    UIImage* image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [_videoRoom startPrewViewWithCanvas:[KKRTCCanvas canvasWithUid:0 view:_localView renderMode:KKRTC_Render_Hidden]];
}
-(void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    [_videoRoom stopPrewViewWithUid:0];
    [_videoRoom leaveRoom:nil];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)joinWithRoomID:(NSInteger)roomID ID:(NSString*)userName{
    @synchronized (self) {
        [_videoRoom joinRoomWithRoomID:ROOM_ID userName:userName completeCallback:^(BOOL isSuccess, NSError *error) {
            
            NSLog(@"error");
        }];
    }
}

#define MARGGING 10
#define ITEM_COUNT 3
-(void)addRemoteView:(UIView*)view withSize:(CGSize)size{
    
    [UIView animateWithDuration:0.5 animations:^{
        [self.view addSubview:view];
        view.frame = [self getFrameWithIndex:_remotes.count withSize:(CGSize)size];
    }];
    
}

-(CGRect)getFrameWithIndex:(NSInteger)index withSize:(CGSize)size{
    CGSize frameSize = self.view.bounds.size;
    CGFloat height = frameSize.height*0.2;
    CGFloat width = (frameSize.width - ITEM_COUNT * MARGGING)*1.0/ITEM_COUNT;
    
    NSInteger col = index % ITEM_COUNT;
    NSInteger rows = index / ITEM_COUNT + 1;
    CGRect frame = CGRectMake((MARGGING + width)*col, frameSize.height - (MARGGING + height)*rows, width, height);
    
    CGFloat rate =  size.height /size.width;
    if(frame.size.width / frame.size.height > size.width / size.height){
        size.height = frame.size.height;
        size.width = size.height / rate;
    }else{
        size.width = frame.size.width;
        size.height = size.width * rate;
    }
    frame.origin.x += (frame.size.width - size.width)/2.0;
    frame.origin.y += (frame.size.height - size.height)/2.0;
    frame.size = size;
    return frame;
}

-(void)deleteRemoteView:(UIView*)view{
    
    [UIView animateWithDuration:0.5 animations:^{
        KKRTCCanvas* remote = nil;
        for (int i = 0; i < _remotes.count; i++) {
            if (!remote) {
                if (_remotes.allValues[i].view == view) {
                    remote = _remotes.allValues[i];
                    [view removeFromSuperview];
                }
            }else{
                CGSize size = _remotes.allValues[i-1].view.frame.size;
                _remotes.allValues[i].view.frame = [self getFrameWithIndex:i-1 withSize:size];
            }
            
        }
    }];
    
}

//-(void)GJJanusVideoRoom:(GJJanusVideoRoom *)plugin addVideoTrackWithUid:(NSUInteger)uid{

//}
//
//-(void)GJJanusVideoRoom:(GJJanusVideoRoom *)plugin delVideoTrackWithUid:(NSUInteger)uid{
//    KKRTCCanvas* canvas = _remotes[@(uid)];
//    [self deleteRemoteView:canvas.view];
//    [_remotes removeObjectForKey:@(uid)];
//}

-(void)GJJanusVideoRoom:(GJJanusVideoRoom *)plugin didJoinRoomWithID:(NSUInteger )clientID{
    
}
-(void)GJJanusVideoRoom:(GJJanusVideoRoom *)plugin newRemoteJoinWithID:(NSUInteger )clientID{
    
}

-(void)GJJanusVideoRoom:(GJJanusVideoRoom *)plugin remoteLeaveWithID:(NSUInteger )clientID{
    KKRTCCanvas* canvas = [_videoRoom stopPrewViewWithUid:clientID];
    if (canvas) {
        [self deleteRemoteView:canvas.view];
        [_remotes removeObjectForKey:@(clientID)];
    }
}

-(void)GJJanusVideoRoom:(GJJanusVideoRoom *)plugin firstFrameDecodeWithSize:(CGSize)size uid:(NSUInteger)clientID{
    UIView* remoteView = [[GJVideoBoxView alloc]init];
    remoteView.backgroundColor = [UIColor blackColor];
    [self addRemoteView:remoteView withSize:size];
    KKRTCCanvas* remote = [KKRTCCanvas canvasWithUid:clientID view:remoteView renderMode:KKRTC_Render_Hidden];
    if ([_videoRoom startPrewViewWithCanvas:remote]) {
        _remotes[@(clientID)] = remote;
    }else{
        [self deleteRemoteView:remoteView];
        assert(0);
    }
}

-(void)GJJanusVideoRoom:(GJJanusVideoRoom *)plugin renderSizeChangeWithSize:(CGSize)size uid:(NSUInteger)clientID{

}

-(void)GJJanusVideoRoom:(GJJanusVideoRoom*)plugin netBrokenWithID:(KKRTCNetBrokenReason)reason{
    switch (reason) {
        case KKRTCNetBroken_websocketFail:
        case KKRTCNetBroken_websocketClose:
        {
            UIAlertController* controller = [UIAlertController alertControllerWithTitle:@"警告" message:[NSString stringWithFormat:@"websocket broken with reson:%ld",(long)reason]  preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction* action = [UIAlertAction actionWithTitle:@"确认" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                [self.navigationController popViewControllerAnimated:YES];
            }];
            [controller addAction:action];
            [self presentViewController:controller animated:YES completion:nil];
            break;
        }
            
        default:
            break;
    }
}

-(void)GJJanusVideoRoom:(GJJanusVideoRoom *)plugin fatalErrorWithID:(KKRTCErrorCode)errorCode{
    assert(0);
}

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{

}

-(void)GJJanusVideoRoomDidLeaveRoom:(GJJanusVideoRoom *)plugin{
    
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
