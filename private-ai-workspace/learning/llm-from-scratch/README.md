# Building an LLM from scratch

I follow Sebastian Raschka, *Build a Large Language Model (From Scratch)*. I write the code by hand from the book, run it on the local GPU (PyTorch with CUDA), and commit it chapter by chapter with my own notes. Book code is not copied here verbatim.

## Progress

| Step | Topic | Status | My note in one line |
|---|---|---|---|
| 1 | Understanding LLMs | | |
| 2 | Working with text data: tokenization, byte pair encoding, embeddings | | |
| 3 | Attention: self-attention, causal masking, multi-head | | |
| 4 | GPT architecture from scratch | | |
| 5 | Pretraining on unlabelled data | | |
| 6 | Fine-tuning for classification | | |
| 7 | Instruction fine-tuning | | |
| Capstone | LoRA fine-tune on public PowerShell and Microsoft 365 data, served in Ollama, compared with the base model on a fixed question set | | |

## Capstone rules

- Public data only (documentation and open repositories with compatible licences).
- The evaluation set is fixed before training, so the comparison is fair.
- I report the result even if the fine-tune does not beat the base model.
