//
//  ViewController.swift

import UIKit
import AVFoundation

class ViewController: UIViewController, AVAudioPlayerDelegate {

    @IBOutlet var progressView: UIProgressView!
    @IBOutlet var sliderSeek: UISlider!
    @IBOutlet var sliderVolume: UISlider!
    @IBOutlet var labelCurrent: UILabel!
    @IBOutlet var labelEnd: UILabel!
    @IBOutlet var labelTitle: UILabel!
    @IBOutlet var labelArtist: UILabel!
    @IBOutlet var buttonPlayPause: UIButton!
    @IBOutlet var buttonPrevious: UIButton!
    @IBOutlet var buttonNext: UIButton!
    @IBOutlet var buttonVolume: UIButton!
    @IBOutlet var imageViewAlbumCover: UIImageView!
    @IBOutlet var textViewLyrics: UITextView!
    
    var audioPlayer: AVAudioPlayer!
    var audioFile: URL!
    var timer: Timer?
    var isMute = 0
    var volumeTemp = 0.0
    
    //MARK: -초기화
    override func viewDidLoad() {
        super.viewDidLoad()
        
        selectAudioFile()
        initPlayer()
    }

    func selectAudioFile() {
        audioFile = Bundle.main.url(forResource: "project", withExtension: "mp3")
        //Bundle = 리소스 쪽
        
        //MARK: --메타데이터 갈무리
        let playerItem = AVPlayerItem(url: audioFile)
        let metadata = playerItem.asset.metadata
        let songAsset = AVURLAsset(url: audioFile)
        let lyc = songAsset.lyrics
        for item in metadata {
            guard let key = item.commonKey?.rawValue, let value = item.value else {
                continue
            }
            
            switch key {
                case "title" : labelTitle.text = value as? String
                case "artist" : labelArtist.text = value as? String
                case "artwork" where value is Data : imageViewAlbumCover.image = UIImage(data: value as! Data)
                default:
                    continue
            }
            
            textViewLyrics.text = lyc
        }
        
    }
        
    func initPlayer() {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: audioFile)
        } catch let error as NSError {
            print("error init player", error)
        }
        audioPlayer.delegate = self
        audioPlayer.prepareToPlay() //메모리에 음원 인풋(버퍼링)
        audioPlayer.volume = 0.3
        volumeTemp = Double(audioPlayer.volume)
        
        //MARK: --현재 시간 초기화
        labelCurrent.text = "00:00"
        let min = Int(audioPlayer.duration) / 60
        let sec = Int(audioPlayer.duration) % 60
        
        if min < 10 {
            if sec < 10 {
                labelEnd.text = String("0\(min):0\(sec)")
            } else {
                labelEnd.text = String("0\(min):\(sec)")
            }
        } else if min < 60 {
            if sec < 10 {
                labelEnd.text = String("\(min):0\(sec)")
            } else {
                labelEnd.text = String("\(min):\(sec)")
            }
        } else {
            labelEnd.text = String("out of range")
        }
        
        //MARK: --음악 시간 초기화
        timer = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(callbackTimer), userInfo: nil, repeats: true)
        
        //MARK: --볼륨 초기화
        sliderVolume.maximumValue = 1.0
        sliderVolume.value = 0.3
        volumeTemp = Double(sliderVolume.value)
        
        //MARK: --진행도 초기화
        progressView.progress = 0
        
        //MARK: --재생 버튼 초기화
        buttonPlayPause.setTitle("▶️", for: .normal)
        buttonPlayPause.titleLabel?.font = .systemFont(ofSize: 50)
        
        //MARK: --검색 슬라이드 초기화
        sliderSeek.maximumValue = Float(audioPlayer.duration)
        sliderSeek.value = 0
        
        //MARK: --앨범 아트 초기화
        self.imageViewAlbumCover.transform = CGAffineTransform(scaleX: 0.7, y: 0.7)
        
        //MARK: --가사창 초기화
        textViewLyrics.isHidden = true
     }
    
    //MARK: -재생시간 실시간 반영
    @objc func callbackTimer() {
        let min = Int(audioPlayer.currentTime) / 60
        let sec = Int(audioPlayer.currentTime) % 60
        if min < 10 {
            if sec < 10 {
                labelCurrent.text = String("0\(min):0\(sec)")
            } else {
                labelCurrent.text = String("0\(min):\(sec)")
            }
        } else if min < 60 {
            if sec < 10 {
                labelCurrent.text = String("\(min):0\(sec)")
            } else {
                labelCurrent.text = String("\(min):\(sec)")
            }
        } else {
            labelCurrent.text = String("out of range")
        }
        progressView.progress = Float(audioPlayer.currentTime/audioPlayer.duration)
        sliderSeek.value = Float(audioPlayer.currentTime/audioPlayer.duration)*sliderSeek.maximumValue
//        print("sliderse:\(sliderSeek.value)")
//        print("progress:\(progressView.progress)")
        if sliderSeek.value >= sliderSeek.maximumValue {
            isStop()
        }
//        print("volume: ", volumeTemp)
    }
    
    //MARK: -재생 버튼 기능
    @IBAction func onBtnPlayPause(_ sender: UIButton) {
//        audioPlayer.play()
        print(audioPlayer.isPlaying)
        if audioPlayer.isPlaying {
            audioPlayer.pause()
            buttonPlayPause.setTitle("▶️", for: .normal)
            buttonPlayPause.titleLabel?.font = .systemFont(ofSize: 50)
            zoomPause()
        } else {
            audioPlayer.play()
            buttonPlayPause.setTitle("⏸", for: .normal)
            buttonPlayPause.titleLabel?.font = .systemFont(ofSize: 50)
            zoomPlay()
        }
    }
    
    //MARK: -볼륨 기능
    @IBAction func onSliderVolume(_ sender: UISlider) {
        audioPlayer.volume = sliderVolume.value
        volumeTemp = Double(audioPlayer.volume)
        print(Float(volumeTemp))
    }
    
    //MARK: -검색 슬라이드 기능
    @IBAction func onSliderSeek(_ sender: UISlider) {
//        audioPlayer.pause()
        audioPlayer.currentTime = TimeInterval(sliderSeek.value)
//        audioPlayer.play()
        
        progressView.progress = Float(audioPlayer.currentTime/audioPlayer.duration)
    }
    
    //MARK: -음소거 버튼 기능
    @IBAction func onBtnMute(_ sender: UIButton) {
        if isMute == 0 {
            isMute = 1
            audioPlayer.volume = 0
            sliderVolume.value = 0
            buttonVolume.setTitle("🔇", for: .normal)
            buttonVolume.titleLabel?.font = .systemFont(ofSize: 40)

//            print(isMute)
        } else if isMute == 1 {
            isMute = 0
            audioPlayer.volume = Float(volumeTemp)
            sliderVolume.value = audioPlayer.volume
            buttonVolume.setTitle("🔈", for: .normal)
            buttonVolume.titleLabel?.font = .systemFont(ofSize: 40)
//            print(isMute)
        }
    }
    
    //MARK: -가사 토글 기능
    @IBAction func onSwitchLyrics(_ sender: UISwitch) {
        if sender.isOn {
            textViewLyrics.isHidden = false
        } else {
            textViewLyrics.isHidden = true
        }
    }
    
    //MARK: -재생/일시정지
    func isStop() {
        progressView.progress = 0
        sliderSeek.value = 0
        buttonPlayPause.setTitle("▶️", for: .normal)
        buttonPlayPause.titleLabel?.font = .systemFont(ofSize: 50)
    }
    
    //MARK: -재생할 때 앨범아트 확대
    func zoomPlay() {
        UIView.animate(withDuration: 0.5, animations: {
            self.imageViewAlbumCover.transform = CGAffineTransform(scaleX: 1, y: 1)
        })
    }
    
    //MARK: -일시정지 때 앨범아트 축소
    func zoomPause() {
        UIView.animate(withDuration: 0.5, animations: {
            self.imageViewAlbumCover.transform = CGAffineTransform(scaleX: 0.7, y: 0.7)
        })
    }
    
    //TODO: 5초 뒤로 5초 앞으로 추가
}
