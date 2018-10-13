import quail
import glob
import pandas
import numpy as np
import itertools
import re
from matplotlib import pyplot as plt

datadir = '/Users/jamalw/Desktop/PNI/music_context_reinstatement/data/'
subj_dir = glob.glob(datadir + 'MCR*')
subj = [2,3,6,11,12]
presented_words = []
recalled_words = []
cond_list_all = []

def condition_list(subj_dir,subj):
    cond_list = np.zeros(12)
    subj_id = subj_dir[subj].split("/data/",1)[1]
    infile = subj_dir[subj] + "/data/" + subj_id + "_mcr.log"
    important = []
    keep_phrases = ["conditions"]

    with open(infile) as f:
        f = f.readlines()

    for line in f:
        for phrase in keep_phrases:
            if phrase in line:
                important.append(line)
                break
    
    for i in range(len(important)):
        m = re.search(': (.+?)\n', important[i])
        found = m.group(1)
        cond_list[i] = int(found)

    return cond_list

for s in subj:
    pres1 = []
    for run in range(12):
        # Make presented words list of lists 
        l1 = pandas.read_csv(subj_dir[s] + '/stimuli/word_lists/' + str(run+1) + '_0.csv',header=None, usecols=[0],squeeze=True)
        l2 = pandas.read_csv(subj_dir[s] + '/stimuli/word_lists/' + str(run+1) + '_1.csv',header = None, usecols=[0],squeeze=True)
        pres1.append(l1)
        pres1.append(l2)
        # Make recall words list of lists
        rec1 = np.load(subj_dir[s] +  '/data/recall_data.npy')
        # This line repeats subjects recall twice to match the word presentations structure. Specifically, since words from their recall (which was one long recall of all 24 words) may be contained in either L1 or L2.       
        rep_recalls = list(itertools.chain.from_iterable(itertools.repeat(x, 2) for x in rec1))
    cond_list = condition_list(subj_dir,s)
    cond_list_all.append(cond_list) 
    pres_subj = np.squeeze(pres1)
    presented_words.append(pres_subj) 
    recalled_words.append(rep_recalls)

pres2 = np.squeeze(presented_words)

multisubject_egg = quail.Egg(pres=pres2.tolist(), rec=recalled_words)
acc = multisubject_egg.analyze('accuracy')

list_num = np.tile([0,1],12)

ABA = {}
ABA['L1'] = []
ABA['L2'] = []

AAA = {}
AAA['L1'] = []
AAA['L2'] = []

AAB = {}
AAB['L1'] = []
AAB['L2'] = []

ABB = {}
ABB['L1'] = []
ABB['L2'] = []

for s in range(len(subj)):
    rep_conds = list(itertools.chain.from_iterable(itertools.repeat(int(x), 2) for x in cond_list_all[s]))
    for i in range(len(list_num)):
        list_acc = acc.get_data().loc[s].as_matrix()[i][0]
        if list_num[i] == 0 and rep_conds[i] == 0:
            ABA['L1'].append(list_acc)
        elif list_num[i] == 1 and rep_conds[i] == 0:
            ABA['L2'].append(list_acc)
        elif list_num[i] == 0 and rep_conds[i] == 1:
            AAA['L1'].append(list_acc)
        elif list_num[i] == 1 and rep_conds[i] == 1:
            AAA['L2'].append(list_acc)
        elif list_num[i] == 0 and rep_conds[i] == 2:
            AAB['L1'].append(list_acc)
        elif list_num[i] == 1 and rep_conds[i] == 2:
            AAB['L2'].append(list_acc)
        elif list_num[i] == 0 and rep_conds[i] == 3:
            ABB['L1'].append(list_acc)
        elif list_num[i] == 1 and rep_conds[i] == 3:
            ABB['L2'].append(list_acc)

# plot results
ABA_L1 = np.mean(ABA['L1'])
ABA_L2 = np.mean(ABA['L2'])
AAA_L1 = np.mean(AAA['L1'])
AAA_L2 = np.mean(AAA['L2'])
AAB_L1 = np.mean(AAB['L1'])
AAB_L2 = np.mean(AAB['L2'])
ABB_L1 = np.mean(ABB['L1'])
ABB_L2 = np.mean(ABB['L2'])

N = 4
ind = np.arange(N)
width = 0.35
cond_names = ['ABA','AAA','AAB','ABB']
L1 = np.array([ABA_L1,AAA_L1,AAB_L1,ABB_L1])
L2 = np.array([ABA_L2,AAA_L2,AAB_L2,ABB_L2])

df = pandas.DataFrame(np.c_[L1,L2], index=cond_names)

df.plot.bar()

plt.legend(['L1','L2'])
plt.title('Correct Recalls for L1 and L2')
plt.ylabel('Proportion Correct')

plt.show()


        
    



