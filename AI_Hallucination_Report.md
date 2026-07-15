# AI 할루시네이션: 사례와 평가법 종합 보고서

> **작성일:** 2026-07-15  
> **조사 방법:** Agent-Reach (Exa 검색 + Jina Reader) 기반 전면 조사  
> **참고 논문:** 100편 이상의 최신 연구 (2023-2026)

---

## 목차

1. [할루시네이션이란?](#1-할루시네이션이란)
2. [할루시네이션 분류 체계 (Taxonomy)](#2-할루시네이션-분류-체계)
3. [도메인별 실제 사례](#3-도메인별-실제-사례)
4. [할루시네이션 평가법 및 메트릭](#4-할루시네이션-평가법-및-메트릭)
5. [주요 벤치마크 및 데이터셋](#5-주요-벤치마크-및-데이터셋)
6. [검출 방법론](#6-검출-방법론)
7. [완화 전략 (Mitigation)](#7-완화-전략)
8. [핵심 수치 및 현황](#8-핵심-수치-및-현황)
9. [참고 문헌](#9-참고-문헌)

---

## 1. 할루시네이션이란?

**정의:** AI 모델이 실제와 다르거나 근거 없는 내용을 그럴듯하게 생성하는 현상

> "Hallucination is output that sounds plausible but is factually wrong, fabricated, or unsupported."  
> — Morph LLM (2026)

### 왜 발생하는가?

LLM은 **다음 토큰의 확률을 예측**하는 것이지, **정확성을 예측하는 것이 아님**. 이 구조적 특성 때문에 할루시네이션은 이론적으로 완전히 제거할 수 없다고 간주된다.

> "Given the theoretical inevitability in computable LLMs, irrespective of architecture or training, future efforts must focus on robust detection, mitigation, and continuous human oversight."  
> — Cossio et al. (2025), arXiv:2508.01781

---

## 2. 할루시네이션 분류 체계

### 2.1 대분류: 충실도 vs 사실성

| 구분 | 설명 | 검출 난이도 |
|------|------|------------|
| **충실도 할루시네이션** (Faithfulness) | 입력 컨텍스트와 불일치 | 소스 문서 비교로 검출 가능 |
| **사실성 할루시네이션** (Factuality) | 세계 지식과 불일치 | 외부 지식 베이스 필요 |

### 2.2 HAD 모델의 11개 세분류 (ACL 2026)

**충실도 할루시네이션 (6개):**

| 번호 | 유형 | 설명 |
|------|------|------|
| 1 | TTII (Task Type Inconsistency) | 지시된 작업 유형과 다른 출력 |
| 2 | TRI (Task Requirement Inconsistency) | 형식, 길이 등 요구사항 미준수 |
| 3 | CwIC (Contradiction with Input Content) | 입력 내용과 모순 |
| 4 | BI (Baseless Information) | 근거 없는 정보 추가 |
| 5 | IO (Information Omission) | 필수 정보 누락 |
| 6 | CwOC (Contradiction within Output Content) | 출력 내 모순 |
| 7 | SI (Structural Incoherence) | 비구조적, 반복적 출력 |

**사실성 할루시네이션 (4개):**

| 번호 | 유형 | 설명 |
|------|------|------|
| 8 | FRE (Factual Recall Error) | 잘못된 사실 인용 |
| 9 | FIE (Factual Inference Error) | 사실 왜곡, 인과 관계 오류 |
| 10 | FE (Fabricated Entity) | 존재하지 않는 인물/단체/개념 생성 |
| 11 | FA (Fictional Attribution) | 실존 인물에 대한 허위 속성 부여 |

### 2.3 기하학적 분류 (2026)

| 유형 | 기하학적 특징 | 검출 가능성 |
|------|-------------|------------|
| Type I: 쿼리 근접 비충실도 | 쿼리 임베딩 근처에 위치 | 각도 비율로 검출 가능 |
| Type II: 관형 (confabulation) | 합리성 영역 외부에 위치 | 방향 서명으로 검출 가능 |
| Type III: 사실 오류 | 합리성 영역 내부에 위치 | **기하학적으로 검출 불가** |

> 핵심 발견: 동일한 어휘, 주제, 구문 프레임을 공유하는 사실 오류는 기하학적으로 구분할 수 없다.

---

## 3. 도메인별 실제 사례

### 3.1 법조계 (가장 심각)

**현황 (2026년 기준):**
- 전 세계 **700건 이상**의 법정 사건에서 AI 할루시네이션 관련 문제 발생
- 미국에서만 **486건**의 보고된 사례 (联邦/주/부족 법원)
- LLM의 법적 쿼리 할루시네이션 비율: **69-88%**

**주요 사례:**

| 사건 | 연도 | 내용 | 결과 |
|------|------|------|------|
| Walmart 사건 (Wyoming) | 2025 | Morgan & Morgan 변호사 3명, ChatGPT로 생성한 허위 판례 인용 | 벌금 $5,000 |
| Utah 주 Clerk 사건 | 2025 | 비면허 법원 서기가 ChatGPT로 작성한 소장에 허위 인용 포함 | 해고 + $1,000 기부 명령 |
| CorMedix 사건 (New Jersey) | 2025 | 연방 판사의 판결문에 허위 인용 및 인용 오류 발견 | 판결문 철회 |
| MyPillow Mike Lindell | 2025 | AI 생성 판례 인용 | 벌금 부과 |
| Arizona 사건 (Mavy v. SSA) | 2025 | 19건 중 12건이 허위/오류 판례 | 변호사 징계 |
| Mississippi 판사 사건 | 2025 | 연방 판사 Henry Wingate, Perplexity AI 생성 정보를 판결문에 사용 | 판결문 철회, 사과 |

> "There are now hundreds of reported instances of lawyers (including those from top law firms), expert witnesses, and even judges filing documents in court that contain hallucinated citations."  
> — Matthew Dahl, Yale University

### 3.2 의료 분계

**현황:**
- Whisper (OpenAI) 의료 전사 할루시네이션 비율: **1.4%** (전체 전사의)
- 장기 임상 사례에서 할루시네이션 비율: **최대 64.1%** (완화 기법 미적용 시)
- 최적 모델(GPT-4o)도 완화 후 **23%** 할루시네이션 발생
- 의료 전문가의 **91.8%**가 AI 할루시네이션 경험

**의료 할루시네이션 유형:**

| 유형 | 예시 |
|------|------|
| 사실 오류 | 잘못된 약물 용량, 부작용 기록 |
| 허위 인용 | 존재하지 않는 의학 문헌 인용 |
| 낡은 정보 | 오래된 치료 지침 인용 |
| 인과 추론 오류 | 진단-치료 연결 오류 |
| Whisper 특이 | "hyperactivated antibiotics" 같은 허약 약물명 생성, 인종차별적 발언 삽입 |

> Pieces Technologies (Dallas) 사건: 의료 AI 정확도를 "<1 per 100,000 오류율"로 광고했으나, 텍사스 AG 조사 결과 허위로 판명. Texas AG와 합의.

### 3.3 코딩/개발

**현황:**
- 576,000개 Python/JavaScript 코드 샘플 분석 (16개 LLM)
- **약 20%**가 존재하지 않는 패키지를 권장
- **440,445개**의 허위 패키지 참조, **205,474개**의 고유 허위 패키지명

**코딩 할루시네이션 유형:**

| 유형 | 예시 | 검출 난이도 |
|------|------|------------|
| 존재하지 않는 패키지 | `import financial_analytics` | 쉬움 (설치 실패) |
| 폐기된 API | v2의 제거된 메서드를 v4 코드베이스에서 사용 | 보통 |
| 잘못된 API 시그니처 | 2개 인자를 받는 함수에 3개 전달 | 보통 |
| 미묘한 로직 오류 | 루프 경계의 오프바이-one, 잘못된 비교 연산자 | 어려움 |
| 허위 설정 옵션 | 라이브러리가 지원하지 않는 플래그 설정 | 어려움 |

> **공급망 공격 위험:** 공격자가 LLM의 허위 패키지명을 수집하여 npm/PyPI에 등록하고 악성코드를 삽입하는 공격 벡터로 악용 가능

### 3.4 일반/종합

**Vectara HHEM 벤치마크 결과 (2025-2026):**

| 모델 | 할루시네이션 비율 (원본) | 할루시네이션 비율 (강화) |
|------|----------------------|----------------------|
| Gemini 2.0 Flash | 0.7% | - |
| Gemini 2.5 Flash Lite | - | 3.3% |
| Claude Sonnet 4.5 | - | >10% |
| GPT-5 | - | >10% |
| Falcon 7B | 29.9% | - |

> 2021년 평균 38% → 2026년 평균 **약 8.2%**로 감소. 그러나 8.2%는 12건 중 1건이 허위 정보라는 의미.

---

## 4. 할루시네이션 평가법 및 메트릭

### 4.1 메트릭 분류 체계

```
평가 메트릭
├── 어휘 기반 (Lexical)
│   ├── ROUGE-L
│   ├── BLEU / SacreBLEU
│   ├── Exact Match (EM)
│   └── Knowledge-F1
├── 의미 기반 (Semantic)
│   ├── BERTScore / Knowledge-BERTScore
│   ├── NLI (Natural Language Inference)
│   └── MoverScore
├── QA 기반 (Question-Answering)
│   ├── Q² (Question-Answering Consistency)
│   ├── Knowledge-F1
│   └── F1-score
├── 모델 기반 (Model-based)
│   ├── GPT-4 Judge (LLM-as-Judge)
│   ├── UniEval
│   └── Consistency / Groundedness
├── 자체 검증 (Self-verification)
│   ├── SelfCheckGPT
│   ├── Chain-of-Verification
│   └── SelfElicit
└── 앙상블
    ├── Ensemble (FAMD 기반)
    └── HalluScore (새롭게 제안)
```

### 4.2 메트릭별 성능 비교 (EMNLP 2025 대규모 평가)

**37개 모델, 5개 패밀리, 4개 데이터셋에서의 검증 결과:**

| 메트릭 | 인간 판단 정합성 | 범용성 | 비고 |
|--------|----------------|--------|------|
| GPT-4 Judge | **가장 우수** | 높음 | 2개 데이터셋에서 최고 성능 |
| Q² NLI | 보통-우수 | 중간 | Begin CMU, HaluEval QA에서 강세 |
| Knowledge-BERTScore | 보통-우수 | 중간 |Begin CMU에서 강세 |
| Critic (NLI) | 높음 (Begin) | 낮음 | HaluEval에서 랜덤보다 낮음 |
| UniEval | **매우 낮음** | 낮음 | 랜덤 수준 이하 |
| ROUGE-L | 낮음 | 높음 | 정밀도 극히 낮음 |
| SacreBLEU | 낮음 | 보통 | 의미적 평가 불가 |

> **핵심 발견:** GPT-4를 제외한 메트릭은 인간 판단과 일관된 정합성을 보이지 못한다.

### 4.3 HalluScore (2026 새 메트릭)

- NLI Verification: AUROC **0.88** (최고 성능)
- RAV: AUROC **0.66** (2위)
- 인간 전문가 판단과의 상관관계: **Pearson r = 0.41**

---

## 5. 주요 벤치마크 및 데이터셋

### 5.1 종합 벤치마크

| 벤치마크 | 유형 | 규모 | 특징 |
|---------|------|------|------|
| **TruthfulQA** | 사실성 QA | 817문항, 38카테고리 | 오해를 유발하는 질문 포함 |
| **HaluEval** | 할루시네이션 평가 | QA + 요약 + 대화 | 합성 데이터 기반 |
| **FactScore** | 사실성 분해 | 장문 생애 기록 | 원자적 사실 단위로 분해 |
| **HHEM** (Vectara) | 요약 충실도 | 7,700+ 기사 | RAG 기반 LLM 순위표 |
| **FaithBench** | 충실도 | 10개 LLM 요약 | 인간 어노테이션 포함 |
| **HaluScan** | 범용 | 72구성, 6검출법 | HalluScore 메트릭 포함 |
| **OpenHalDet** | 통합 검출 | 다양한 생성 시나리오 | 검출기 패밀리 통합 |
| **RAGTruth** | RAG 할루시네이션 | ~18,000 응답 | 단어 수준 어노테이션 |

### 5.2 도메인 특화 벤치마크

| 벤치마크 | 도메인 | 특징 |
|---------|--------|------|
| SciFact | 과학 | 논문 기반 팩트체크 |
| PubMedQA | 의료 | 바이오메디컬 QA |
| MedMCQA | 의료 | 의대 시험 스타일 |
| BioASQ | 의료 | 바이오메디컬 시맨틱 QA |
| COVID-Fact | 의료 | COVID-19 관련 팩트체크 |
| FELM | 다중 도메인 | 과학, 수학, 법률 등 |

### 5.3 RAG 평가 벤치마크

| 벤치마크 | 특징 |
|---------|------|
| FEVER | 팩트 검증 (위키피디아 기반) |
| FEVEROUS | 구조화된 소스 포함 |
| HOVER | 멀티홉 QA |
| LIAR | 정치/뉴스 주장 |
| AggreFact | 추출 합성 |

---

## 6. 검출 방법론

### 6.1 확률 기반 (Probability-based)

- **토큰 확률 분석:** 낮은 확률 토큰이 포함된 응답 할루시네이션 가능성 높음
- **퍼플렉시티:** 높은 퍼플렉시티 = 높은 불확실성 = 할루시네이션 가능성
- **한계:** 모델이 확신을 가지고 잘못된 답변을 생성할 수 있음

### 6.2 특징 기반 (Feature-based)

- **NLI (Natural Language Inference):** 생성된 텍스트와 소스 문서의 모순 검출
  - 가장 널리 사용되는 자동화 방법
  - 내재 할루시네이션 검출에 효과적
- **의미적 유사도:** BERTScore 등으로 소스와의 의미적 거리 측정

### 6.3 일관성 기반 (Consistency-based)

- **SelfCheckGPT:** 동일 프롬프트로 여러 번 생성하여 일관성 검증
  - 일관된 응답 = 팩트일 가능성 높음
  - 불일치한 응답 = 할루시네이션 가능성
- **Chain-of-Verification (CoVe):** 생성 후 자체 검증 체인
- **T3 (Think Twice Before Trusting):** 다중 후보 생성 → 반성 → 비교

### 6.4 검색 강화 (Retrieval-Augmented)

- **외부 지식 통합:** Google Search API 등으로 관련 문서 검색 후 검증
- **RAG 통합:** 검색된 문서와 비교하여 할루시네이션 검출
- **한계:** 검색 품질에 크게 의존

### 6.5 LLM-as-Judge

- **GPT-4 평가:** 현재 가장 신뢰할 수 있는 자동 검출 방법
- **FaithJudge:** 인간 어노테이션된 할루시네이션 예시를 활용한 LLM 평가
- **한계:** 평가 모델 자체도 같은 주제에 대해 할루시네이션할 수 있음

---

## 7. 완화 전략

### 7.1 학습 단계

| 전략 | 설명 | 효과 |
|------|------|------|
| Instruction Tuning | 지시 준수 능력 향상 | 할루시네이션 감소 |
| 사실적 정렬 학습 | 사실성 중심 학습 | 높은 비율 감소 |
| Knowledge Distillation | 지식 증류를 통한 정확도 향상 | 도메인별 효과 |

### 7.2 추론 단계

| 전략 | 설명 | 효과 |
|------|------|------|
| Greedy/Beam Search | 확률적 샘플링 대신 모드 추구 | 할루시네이션 감소 |
| CoT (Chain-of-Thought) | 단계적 추론 유도 | 의료 38% 감소 |
| Self-Consistency | 다중 샘플링 → 다수결 | 불일치 검출 |
| Constrained Decoding | 구조화된 출력 강제 | 패키지 할루시네이션 감소 |

### 7.3 시스템 단계

| 전략 | 설명 | 효과 |
|------|------|------|
| **RAG** | 외부 지식 검색으로 근거 제시 | **60-80% 감소** |
| 모델 라우팅 | 단순 작업은 저비용 모델, 복잡한 작업은 고성능 모델 | 비용 40-70% 절감 + 할루시네이션 집중 관리 |
| 코드 검색 그라운딩 | 실제 코드베이스 검색 후 생성 | 코드 할루시네이션 대폭 감소 |
| human-in-the-loop | 특정 도메인에서 인간 검증 필수 | 최종 안전장치 |

---

## 8. 핵심 수치 및 현황

### 8.1 할루시네이션 비율 현황 (2026)

| 도메인 | 평균 할루시네이션 비율 | 비고 |
|--------|---------------------|------|
| 종합 (2021) | **38%** | 과거 기준 |
| 종합 (2026) | **8.2%** | 개선되었으나 여전히 심각 |
| 법적 쿼리 | **69-88%** | 가장 높은 비율 |
| 법적 (최고 모델) | **6.4%** | 최고 모델도 6% 이상 |
| 의료 | **15.6%** | 환자 안전 직결 |
| 의료 (장기 임상) | **최대 64.1%** | 완화 기법 미적용 시 |
| 코딩/프로그래밍 | **17.8%** | 패키지 할루시네이션 포함 |
| 요약 (최고 모델) | **0.7-3.3%** | HHEM 기준 |

### 8.2 주요 발견

1. **모델 크기와 할루시네이션은 비례하지 않음** — 더 큰 모델이 반드시 덜 할루시네이션하지 않음
2. **RAG가 가장 효과적인 완화 전략** — 60-80% 감소
3. **GPT-4가 가장 신뢰할 수 있는 검출 도구** — 인간 판단과 가장 높은 정합성
4. **기존 메트릭의 한계** — ROUGE 등 어휘 기반 메트릭은 할루시네이션 검출에 부적합
5. **할루시네이션과 헤징은 같은 불확실성 상태의 산물** — 상반된 신호가 아님

### 8.3 법적 규제 동향

- 미국 대법원장 John Roberts (2023 연례 보고서): "AI 사용에는 주의와 겸손이 필요"
- 텍사스주: 의료 AI 기업 Pieces Technologies와 최초의 합의
- 애리조나주: AI 할루시네이션 가이드라인 발표
- 전 세계 법원: 2023년 주 2건 → 2025년 주 2-3건으로 증가 추세

---

## 9. 참고 문헌

### 종합 서베이

1. Cossio, M. (2025). "A comprehensive taxonomy of hallucinations in Large Language Models." arXiv:2508.01781
2. Alansari, A. & Luqman, H. (2026). "Large language models hallucination: A comprehensive survey." Computer Science Review, 13, 100970
3. "A Comprehensive Survey on Hallucination in Large Language Models: Detection, Mitigation, and Open Challenges." (2026) clawRxiv:2604.00817

### 평가 메트릭

4. "Evaluating Evaluation Metrics – The Mirage of Hallucination Detection." EMNLP 2025 Findings
5. Qi, S. et al. (2024). "A Survey of Automatic Hallucination Evaluation on Natural Language Generation." arXiv:2404.12041
6. Malin, B. et al. (2025). "A Review of Faithfulness Metrics for Hallucination Assessment in Large Language Models."

### 벤치마크

7. "HalluScan: A Systematic Benchmark for Detecting and Mitigating Hallucinations." arXiv:2605.02443
8. Li, X. et al. (2026). "OpenHalDet: A Unified Benchmark for Hallucination Detection." arXiv:2606.06959
9. Vectara (2025). "Benchmarking LLM Faithfulness in RAG with Evolving Leaderboards." EMNLP 2025 Industry

### 도메인별

10. "Medical Hallucination in Foundation Models and Their Impact on Healthcare." medRxiv (2025)
11. Morph LLM (2026). "AI Hallucination Examples: A Catalog of What Goes Wrong and Why."
12. Reuters (2025). "AI 'hallucinations' in court papers spell trouble for lawyers."

### 검출 방법

13. "Knowledge-Grounded Detection of Factual Hallucinations in Large Language Models." CLiLit 2025
14. Cleanlab (2025). "Benchmarking Hallucination Detection Methods in RAG."
15. "The Illusion of Progress: Re-evaluating Hallucination Detection in LLMs." EMNLP 2025

---

> **이 보고서는 Agent-Reach를 사용하여 Exa 검색, Jina Reader를 통해 조사된 내용을 종합한 것입니다.**
> **최종 업데이트: 2026-07-15**
